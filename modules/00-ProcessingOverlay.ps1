# Shared shell service, not a registered tool. The separate STA dispatcher keeps
# the indicator alive even while legacy module code is busy on the main UI thread.
# https://learn.microsoft.com/en-us/dotnet/desktop/wpf/advanced/threading-model
# https://learn.microsoft.com/en-us/dotnet/api/system.windows.eventmanager.registerclasshandler
function Global:Initialize-PTSProcessingOverlay {
    if ($Global:PTS_ProcessingService) { return }
    if (-not ('WindowsAcolyte.ProcessingOverlay' -as [type])) {
        $source = @'
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace WindowsAcolyte {
    public sealed class ProcessingOverlay : IDisposable {
        sealed class Operation {
            public string Detail;
            public bool CanCancel;
            public bool CancelRequested;
            public long Started;
        }
        [StructLayout(LayoutKind.Sequential)] struct RECT { public int Left, Top, Right, Bottom; }
        [StructLayout(LayoutKind.Sequential)] struct POINT { public int X, Y; }
        [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
        [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref POINT p);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
        [DllImport("user32.dll")] static extern bool IsWindowEnabled(IntPtr h);
        [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
        [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hgt, uint flags);
        readonly Window owner;
        readonly IntPtr ownerHandle;
        readonly ConcurrentDictionary<string, Operation> operations = new ConcurrentDictionary<string, Operation>();
        readonly ConcurrentQueue<string> cancellations = new ConcurrentQueue<string>();
        readonly Dictionary<RoutedEventArgs,string> actionScopes = new Dictionary<RoutedEventArgs,string>();
        readonly Thread thread;
        readonly ManualResetEventSlim ready = new ManualResetEventSlim();
        Dispatcher dispatcher;
        Window window;
        Grid surface;
        Border card;
        TextBlock title, detail;
        Button cancel;
        Ellipse track;
        System.Windows.Shapes.Path spinner;
        RotateTransform rotation;
        DispatcherTimer timer;
        Exception startupError;
        volatile bool disposed, visible;
        volatile string fault;
        string[] palette;
        string[] appliedPalette;
        readonly int delay;
        static bool handlersInstalled;
        static readonly ConcurrentBag<WeakReference<ProcessingOverlay>> services = new ConcurrentBag<WeakReference<ProcessingOverlay>>();
        static readonly object handlerGate = new object();
        public bool Visible { get { return visible; } }
        public int Count { get { return operations.Count; } }
        public string Fault { get { return fault; } }
        public int ThreadId { get; private set; }
        public double Angle { get { return dispatcher.Invoke(() => rotation.Angle); } }

        public ProcessingOverlay(Window owner, string[] colors, int delayMilliseconds) {
            if (owner == null) throw new ArgumentNullException("owner");
            this.owner = owner;
            ownerHandle = new WindowInteropHelper(owner).EnsureHandle();
            delay = Math.Max(0, delayMilliseconds);
            SetPalette(colors);
            thread = new Thread(Run) { IsBackground = true, Name = "WindowsAcolyte Processing UI" };
            thread.SetApartmentState(ApartmentState.STA);
            thread.Start();
            if (!ready.Wait(10000)) { disposed = true; throw new TimeoutException("Processing UI did not start."); }
            if (startupError != null) throw new InvalidOperationException("Processing UI failed to start.", startupError);
            services.Add(new WeakReference<ProcessingOverlay>(this));
            lock (handlerGate) { if (!handlersInstalled) {
                EventManager.RegisterClassHandler(typeof(ButtonBase), ButtonBase.ClickEvent, new RoutedEventHandler(BeforeAction), true);
                EventManager.RegisterClassHandler(typeof(MenuItem), MenuItem.ClickEvent, new RoutedEventHandler(BeforeAction), true);
                EventManager.RegisterClassHandler(typeof(ToggleButton), ToggleButton.CheckedEvent, new RoutedEventHandler(BeforeAction), true);
                EventManager.RegisterClassHandler(typeof(ToggleButton), ToggleButton.UncheckedEvent, new RoutedEventHandler(BeforeAction), true);
                EventManager.RegisterClassHandler(typeof(Selector), Selector.SelectionChangedEvent, new SelectionChangedEventHandler(BeforeSelection), true);
                handlersInstalled = true;
            } }
            owner.PreviewKeyDown += GuardKeys;
            owner.PreviewKeyUp += GuardKeys;
            owner.PreviewMouseWheel += GuardWheel;
            owner.PreviewMouseDown += GuardMouse;
            owner.Closed += OwnerClosed;
            foreach (var evt in new RoutedEvent[] { ButtonBase.ClickEvent, MenuItem.ClickEvent, ToggleButton.CheckedEvent, ToggleButton.UncheckedEvent })
                owner.AddHandler(evt, new RoutedEventHandler(AfterAction), true);
            owner.AddHandler(Selector.SelectionChangedEvent, new SelectionChangedEventHandler(AfterSelection), true);
            owner.Dispatcher.UnhandledException += ActionFailed;
        }
        static void BeforeSelection(object sender, SelectionChangedEventArgs e) { BeforeAction(sender, e); }
        static void BeforeAction(object sender, RoutedEventArgs e) {
            var visual = sender as DependencyObject;
            if (visual == null) return;
            var host = Window.GetWindow(visual);
            foreach (var reference in services.ToArray()) {
                ProcessingOverlay service;
                if (!reference.TryGetTarget(out service) || service.disposed) continue;
                if (host != service.owner) continue;
                string label = "Processing selected action...";
                var button = sender as ContentControl;
                if (button != null && button.Content is string) label = (string)button.Content;
                var menu = sender as MenuItem;
                if (menu != null && menu.Header is string) label = (string)menu.Header;
                var id = "action:" + Guid.NewGuid().ToString("N");
                if (service.actionScopes.ContainsKey(e)) continue;
                service.actionScopes[e] = id;
                service.Begin(id, label, false);
            }
        }
        void AfterSelection(object sender, SelectionChangedEventArgs e) { AfterAction(sender,e); }
        void AfterAction(object sender, RoutedEventArgs e) {
            string id;
            if (!actionScopes.TryGetValue(e,out id)) return;
            actionScopes.Remove(e);
            // Called at the end of the routed event, not during a nested dialog's
            // dispatcher loop. Keep the token until queued layout work completes.
            EndAfterRender(id);
        }
        void ActionFailed(object sender, DispatcherUnhandledExceptionEventArgs e) {
            if (!IsWindowEnabled(ownerHandle)) return; // A nested modal UI owns this exception.
            foreach (var id in actionScopes.Values) End(id);
            actionScopes.Clear();
        }
        void GuardKeys(object sender, KeyEventArgs e) {
            if (!visible || !IsWindowEnabled(ownerHandle)) return;
            if (e.Key == Key.System && e.SystemKey == Key.F4) return; // Existing close/operation warning.
            if (e.Key == Key.Escape) RequestCancellation();
            e.Handled = true;
        }
        void OwnerClosed(object sender, EventArgs e) { Dispose(); }
        void GuardWheel(object sender, MouseWheelEventArgs e) { if (visible && IsWindowEnabled(ownerHandle)) e.Handled = true; }
        void GuardMouse(object sender, MouseButtonEventArgs e) { if (visible && IsWindowEnabled(ownerHandle)) e.Handled = true; }
        public void SetPalette(string[] colors) {
            if (colors == null || colors.Length != 5) throw new ArgumentException("Five overlay colors required.");
            foreach (var color in colors) ColorConverter.ConvertFromString(color);
            Interlocked.Exchange(ref palette, (string[])colors.Clone());
        }
        public void Begin(string id, string text, bool canCancel) {
            if (disposed) return;
            if (String.IsNullOrEmpty(id)) throw new ArgumentException("Operation ID required.");
            operations.AddOrUpdate(id,
                key => new Operation { Detail = text ?? "Please wait...", CanCancel = canCancel, Started = Stopwatch.GetTimestamp() },
                (key, old) => new Operation { Detail = text ?? old.Detail, CanCancel = canCancel, Started = old.Started, CancelRequested = old.CancelRequested });
        }
        public void End(string id) { if (id != null) { Operation ignored; operations.TryRemove(id, out ignored); } }
        public void EndAfterRender(string id) {
            if (disposed) return;
            owner.Dispatcher.BeginInvoke(DispatcherPriority.ContextIdle, new Action(() => End(id)));
        }
        public void RequestCancellation() {
            foreach (var item in operations.ToArray()) {
                if (!item.Value.CanCancel || item.Value.CancelRequested) continue;
                item.Value.CancelRequested = true;
                cancellations.Enqueue(item.Key);
            }
        }
        public string[] TakeCancellationRequests() {
            var result = new List<string>(); string item;
            while (cancellations.TryDequeue(out item)) result.Add(item);
            return result.ToArray();
        }
        public void ResetCancellation(string id) {
            Operation item;
            if (operations.TryGetValue(id,out item)) item.CancelRequested = false;
        }
        void PositionWindow() {
            RECT rect; POINT point = new POINT();
            if (GetClientRect(ownerHandle, out rect) && ClientToScreen(ownerHandle, ref point))
                SetWindowPos(new WindowInteropHelper(window).EnsureHandle(), IntPtr.Zero, point.X, point.Y, rect.Right, rect.Bottom, 0x0010 | 0x0004);
        }
        static Brush Brush(string color) { return new SolidColorBrush((Color)ColorConverter.ConvertFromString(color)); }
        void Run() {
            try {
                ThreadId = Thread.CurrentThread.ManagedThreadId;
                dispatcher = Dispatcher.CurrentDispatcher;
                window = new Window { WindowStyle = WindowStyle.None, ResizeMode = ResizeMode.NoResize,
                    AllowsTransparency = true, Background = Brushes.Transparent, ShowInTaskbar = false,
                    ShowActivated = false, Focusable = false, Title = "WindowsAcolyte - Processing..." };
                new WindowInteropHelper(window).Owner = ownerHandle;
                surface = new Grid();
                AutomationProperties.SetName(surface, "Processing... Please wait.");
                card = new Border { Width = 396, MinHeight = 146, CornerRadius = new CornerRadius(16),
                    BorderThickness = new Thickness(1), Padding = new Thickness(30,26,30,26),
                    HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                var panel = new StackPanel();
                var row = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Center };
                var ring = new Grid { Width = 38, Height = 38, Margin = new Thickness(0,0,17,0) };
                track = new Ellipse { StrokeThickness = 3, Opacity = 0.35, Margin = new Thickness(3) };
                rotation = new RotateTransform();
                spinner = new System.Windows.Shapes.Path { Data = Geometry.Parse("M 19,3 A 16,16 0 1 1 3,19"), StrokeThickness = 3,
                    StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round,
                    RenderTransformOrigin = new Point(0.5,0.5), RenderTransform = rotation };
                ring.Children.Add(track); ring.Children.Add(spinner); row.Children.Add(ring);
                title = new TextBlock { Text = "Processing...", FontSize = 26, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center };
                row.Children.Add(title); panel.Children.Add(row);
                detail = new TextBlock { FontSize = 12, TextAlignment = TextAlignment.Center, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0,16,0,0) };
                panel.Children.Add(detail);
                cancel = new Button { Content = "Cancel", HorizontalAlignment = HorizontalAlignment.Center, Padding = new Thickness(18,6,18,6), Margin = new Thickness(0,16,0,0) };
                cancel.Click += (s,e) => RequestCancellation(); panel.Children.Add(cancel);
                card.Child = panel; surface.Children.Add(card); window.Content = surface;
                timer = new DispatcherTimer(TimeSpan.FromMilliseconds(30), DispatcherPriority.Normal, (s,e) => Tick(), dispatcher);
                ready.Set();
                if (!disposed) Dispatcher.Run();
            } catch (Exception ex) { startupError = ex; fault = ex.ToString(); ready.Set(); }
            finally { visible = false; }
        }
        void Tick() {
            try {
                if (disposed) { window.Close(); dispatcher.BeginInvokeShutdown(DispatcherPriority.Send); return; }
                var items = operations.Values.ToArray();
                bool elapsed = items.Length > 0 && (visible || (Stopwatch.GetTimestamp() - items.Min(x => x.Started)) * 1000.0 / Stopwatch.Frequency >= delay);
                // Native/common dialogs disable their owner. Never cover them.
                if (!elapsed || !IsWindowVisible(ownerHandle) || IsIconic(ownerHandle) || !IsWindowEnabled(ownerHandle)) {
                    if (visible) { window.Hide(); visible = false; rotation.BeginAnimation(RotateTransform.AngleProperty, null); }
                    return;
                }
                var colors = palette;
                if (!Object.ReferenceEquals(appliedPalette, colors)) {
                    surface.Background = Brush("#8800101C"); card.Background = Brush(colors[0]); card.BorderBrush = Brush(colors[1]);
                    track.Stroke = Brush(colors[1]); spinner.Stroke = Brush(colors[2]); title.Foreground = Brush(colors[3]); detail.Foreground = Brush(colors[4]);
                    cancel.Background = Brush(colors[0]); cancel.Foreground = Brush(colors[3]); cancel.BorderBrush = Brush(colors[1]); appliedPalette = colors;
                }
                detail.Text = items.OrderByDescending(x => x.Started).First().Detail;
                bool cancellable = items.Any(x => x.CanCancel);
                bool pending = items.Any(x => x.CanCancel && x.CancelRequested);
                cancel.Visibility = cancellable ? Visibility.Visible : Visibility.Collapsed;
                cancel.IsEnabled = cancellable && !pending; cancel.Content = pending ? "Cancelling..." : "Cancel";
                PositionWindow();
                if (!visible) {
                    window.Show(); visible = true;
                    var animation = new DoubleAnimation(0,360,TimeSpan.FromSeconds(1)) { RepeatBehavior = RepeatBehavior.Forever };
                    rotation.BeginAnimation(RotateTransform.AngleProperty, animation);
                }
                PositionWindow();
            } catch (Exception ex) { fault = ex.ToString(); window.Hide(); visible = false; operations.Clear(); }
        }
        public void Capture(string file) {
            dispatcher.Invoke(() => {
                window.UpdateLayout();
                var image = new RenderTargetBitmap(Math.Max(1,(int)surface.ActualWidth), Math.Max(1,(int)surface.ActualHeight),96,96,PixelFormats.Pbgra32);
                image.Render(surface); var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(image));
                using (var stream = File.Create(file)) encoder.Save(stream);
            });
        }
        public void Dispose() {
            if (disposed) return;
            disposed = true; operations.Clear();
            owner.PreviewKeyDown -= GuardKeys; owner.Closed -= OwnerClosed;
            owner.PreviewKeyUp -= GuardKeys; owner.PreviewMouseWheel -= GuardWheel; owner.PreviewMouseDown -= GuardMouse;
            foreach (var evt in new RoutedEvent[] { ButtonBase.ClickEvent, MenuItem.ClickEvent, ToggleButton.CheckedEvent, ToggleButton.UncheckedEvent })
                owner.RemoveHandler(evt,new RoutedEventHandler(AfterAction));
            owner.RemoveHandler(Selector.SelectionChangedEvent,new SelectionChangedEventHandler(AfterSelection));
            owner.Dispatcher.UnhandledException -= ActionFailed;
            actionScopes.Clear();
            if (dispatcher != null && !dispatcher.HasShutdownStarted) dispatcher.BeginInvoke(DispatcherPriority.Send, new Action(() => { timer.Stop(); window.Close(); dispatcher.BeginInvokeShutdown(DispatcherPriority.Send); }));
            if (Thread.CurrentThread != thread) thread.Join(2000);
        }
    }
}
'@
        $wpfNames = @('PresentationFramework','PresentationCore','WindowsBase','System.Xaml')
        $references = @($wpfNames | ForEach-Object { [Reflection.Assembly]::Load($_).Location })
        $references += @(Get-ChildItem -LiteralPath (Join-Path $PSHOME 'ref') -Filter '*.dll' |
            Where-Object BaseName -notin $wpfNames | Select-Object -ExpandProperty FullName)
        Add-Type -TypeDefinition $source -ReferencedAssemblies $references -ErrorAction Stop
    }
    $Global:PTS_ProcessingService = [WindowsAcolyte.ProcessingOverlay]::new($Global:PTS_Window, (Get-PTSProcessingPalette), 200)
    $Global:PTS_ProcessingPoll = [Windows.Threading.DispatcherTimer]::new()
    $Global:PTS_ProcessingPoll.Interval = [TimeSpan]::FromMilliseconds(100)
    $Global:PTS_ProcessingPoll.Add_Tick({
        foreach ($id in $Global:PTS_ProcessingService.TakeCancellationRequests()) {
            $op = @($Global:PTS_ActiveOperations.Values | Where-Object ProcessingId -eq $id | Select-Object -First 1)[0]
            if ($op -and $op.Cancel -and -not $op.CancelRequested) {
                $op.CancelRequested = $true
                try { & $op.Cancel } catch {
                    $op.CancelRequested = $false
                    $Global:PTS_ProcessingService.ResetCancellation($id)
                    Write-PTSExceptionReport -Context 'Processing.Cancel' -ModuleId $op.ModuleId -ErrorRecord $_
                }
            }
        }
        if ($Global:PTS_ProcessingService.Fault) {
            $Global:PTS_ProcessingPoll.Stop()
            Write-PTSExceptionReport -Context 'Processing.UI' -Exception ([Exception]::new($Global:PTS_ProcessingService.Fault))
        }
    })
    $Global:PTS_ProcessingPoll.Start()
    $Global:PTS_Window.Add_Closed({ $Global:PTS_ProcessingPoll.Stop(); $Global:PTS_ProcessingService.Dispose(); $Global:PTS_ProcessingService=$null })
}

function Global:Get-PTSProcessingPalette {
    $palette = if ($Global:PTS_DarkModeEnabled) { $Global:PTS_ThemeDark } else { $Global:PTS_Theme }
    return [string[]]@($palette.Surface, $palette.Border, $palette.Primary, $palette.TextDark, $palette.TextMuted)
}

function Global:Start-PTSProcessing {
    param([string]$Detail='Please wait...')
    $id = 'scope:' + [guid]::NewGuid().ToString('N')
    if ($Global:PTS_ProcessingService) { $Global:PTS_ProcessingService.Begin($id,$Detail,$false) }
    return $id
}

function Global:Stop-PTSProcessing {
    param([string]$Id)
    if ($Global:PTS_ProcessingService -and $Id) { $Global:PTS_ProcessingService.EndAfterRender($Id) }
}
