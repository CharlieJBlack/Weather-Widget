import SwiftUI
import AppKit
import Combine
import QuartzCore

// MARK: - Private APIs for Lock Screen Window

@_silgen_name("CGShieldingWindowLevel")
private func CGShieldingWindowLevel() -> Int32

// CGS Window Tags
private typealias CGSConnectionID = UInt32
private typealias CGSWindowID = UInt32

@_silgen_name("_CGSDefaultConnection")
private func _CGSDefaultConnection() -> CGSConnectionID

@_silgen_name("CGSSetWindowTags")
private func CGSSetWindowTags(_ cid: CGSConnectionID, _ wid: CGSWindowID, _ tags: UnsafePointer<UInt32>, _ tagCount: Int32) -> OSStatus

@_silgen_name("CGSClearWindowTags")
private func CGSClearWindowTags(_ cid: CGSConnectionID, _ wid: CGSWindowID, _ tags: UnsafePointer<UInt32>, _ tagCount: Int32) -> OSStatus

// Window tags for lock screen visibility
private let kCGSModalWindowTagBit: UInt32 = 1 << 31
private let kCGSStickyTagBit: UInt32 = 1 << 11
private let kCGSHighQualityResamplingTagBit: UInt32 = 1 << 4

// MARK: - Widget Window Controller

@MainActor
class WidgetWindowController: ObservableObject {
    static let shared = WidgetWindowController()

    @Published var isVisible = false
    @Published var widgetPosition: WidgetPosition = .bottomRight
    @Published var widgetStyle: WidgetStyle = .standard
    @Published var alwaysShow: Bool = false

    private var widgetWindow: NSWindow?
    private var hasDelegated = false
    private var cancellables = Set<AnyCancellable>()
    private var screenChangeObserver: NSObjectProtocol?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var hideTask: Task<Void, Never>?

    private let panelCornerRadius: CGFloat = 28

    private init() {
        setupNotifications()
        registerScreenChangeObservers()
        print("[WidgetWindow] Initialized")
    }

    // MARK: - Widget Position

    enum WidgetPosition: String, CaseIterable {
        case topLeft = "Top Left"
        case topRight = "Top Right"
        case bottomLeft = "Bottom Left"
        case bottomRight = "Bottom Right"
        case center = "Center"
    }

    // MARK: - Widget Style

    enum WidgetStyle: String, CaseIterable {
        case standard = "Standard"
        case compact = "Compact"
        case circular = "Circular"
        case detailed = "Detailed"
    }

    // MARK: - Widget Type

    enum WidgetType: String, CaseIterable {
        case weather = "Weather"
        case activity = "Activity"
    }

    @Published var widgetType: WidgetType = .weather

    // MARK: - Setup

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .lockScreenDidActivate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showWidget()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lockScreenDidDeactivate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if !(self?.alwaysShow ?? false) {
                    self?.hideWidget()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .screenSaverDidStart)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showWidget()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .screenSaverDidStop)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if !(self?.alwaysShow ?? false) {
                    self?.hideWidget()
                }
            }
            .store(in: &cancellables)
    }

    private func registerScreenChangeObservers() {
        // Observe screen parameter changes (resolution, display configuration)
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenGeometryChange(reason: "screen-parameters")
        }

        // Observe screen wake events
        let workspaceCenter = NSWorkspace.shared.notificationCenter

        let wakeObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenGeometryChange(reason: "screens-did-wake")
        }

        let sleepObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("[WidgetWindow] Screens did sleep")
        }

        workspaceObservers = [wakeObserver, sleepObserver]
    }

    private func handleScreenGeometryChange(reason: String) {
        guard let window = widgetWindow else { return }
        guard window.isVisible || isVisible else { return }
        guard let screen = NSScreen.main else { return }

        let size = widgetSizeForStyle(widgetStyle)
        let targetFrame = frame(for: size, on: screen)
        window.setFrame(targetFrame, display: true)

        print("[WidgetWindow] Realigned window due to \(reason)")
    }

    // MARK: - Window Management

    private func frame(for size: NSSize, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let padding: CGFloat = 40

        var origin: CGPoint

        switch widgetPosition {
        case .topLeft:
            origin = CGPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.maxY - size.height - padding - 60
            )
        case .topRight:
            origin = CGPoint(
                x: screenFrame.maxX - size.width - padding,
                y: screenFrame.maxY - size.height - padding - 60
            )
        case .bottomLeft:
            origin = CGPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding + 100
            )
        case .bottomRight:
            origin = CGPoint(
                x: screenFrame.maxX - size.width - padding,
                y: screenFrame.minY + padding + 100
            )
        case .center:
            origin = CGPoint(
                x: screenFrame.midX - size.width / 2,
                y: screenFrame.midY - size.height / 2
            )
        }

        return NSRect(origin: origin, size: size)
    }

    private func ensureWindow() -> NSWindow {
        if let window = widgetWindow {
            return window
        }

        guard let screen = NSScreen.main else {
            fatalError("No main screen available")
        }

        let widgetSize = widgetSizeForStyle(widgetStyle)
        let targetFrame = frame(for: widgetSize, on: screen)

        let contentView = WidgetContainerView(
            type: widgetType,
            style: widgetStyle,
            weatherProvider: WeatherProvider.shared,
            activityProvider: ActivityProvider.shared
        )

        // Create window with lock screen compatible settings
        let window = NSWindow(
            contentRect: targetFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure window for lock screen visibility
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovable = false
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.ignoresMouseEvents = false  // Interactive widget for settings
        window.canBecomeVisibleWithoutLogin = true  // KEY: Allow on lock screen

        // Set content view
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: targetFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView

        widgetWindow = window
        hasDelegated = false

        print("[WidgetWindow] Window created with level: \(window.level.rawValue)")
        return window
    }

    func showWidget() {
        print("[WidgetWindow] showWidget() called")

        hideTask?.cancel()
        hideTask = nil

        let window = ensureWindow()

        // Refresh data based on widget type
        if widgetType == .weather {
            WeatherProvider.shared.refresh(force: true)
        } else if widgetType == .activity {
            ActivityProvider.shared.refresh(force: true)
        }

        // Update frame in case screen changed
        if let screen = NSScreen.main {
            let size = widgetSizeForStyle(widgetStyle)
            let targetFrame = frame(for: size, on: screen)
            window.setFrame(targetFrame, display: true)
        }

        // Delegate window to SkyLight space for lock screen visibility
        if !hasDelegated {
            SkyLightOperator.shared.delegateWindow(window)
            hasDelegated = true
        }

        // Also apply CGS window tags for additional visibility
        applyLockScreenTags(to: window)

        // Show with animation
        window.alphaValue = 0
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
        }

        isVisible = true
        print("[WidgetWindow] Widget is now visible")
    }

    private func applyLockScreenTags(to window: NSWindow) {
        let windowID = CGSWindowID(window.windowNumber)
        guard windowID > 0 else {
            print("[WidgetWindow] Invalid window number")
            return
        }

        let connection = _CGSDefaultConnection()

        // Apply sticky tag so window appears on all spaces including lock screen
        var tags: [UInt32] = [kCGSStickyTagBit]
        let result = CGSSetWindowTags(connection, windowID, &tags, 1)

        print("[WidgetWindow] Applied CGS tags, result: \(result)")
    }

    func hideWidget() {
        print("[WidgetWindow] hideWidget() called")

        hideTask?.cancel()

        guard let window = widgetWindow else {
            isVisible = false
            return
        }

        // Animate out then order out
        hideTask = Task { [weak self] in
            // Animate alpha
            await MainActor.run {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().alphaValue = 0
                }
            }

            // Wait for animation
            try? await Task.sleep(for: .milliseconds(250))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                window.orderOut(nil)
                self?.isVisible = false
                print("[WidgetWindow] Widget hidden")
            }
        }
    }

    func toggleWidget() {
        if isVisible {
            hideWidget()
        } else {
            showWidget()
        }
    }

    private func widgetSizeForStyle(_ style: WidgetStyle) -> NSSize {
        switch style {
        case .standard:
            return NSSize(width: 200, height: 200)
        case .compact:
            return NSSize(width: 180, height: 80)
        case .circular:
            return NSSize(width: 90, height: 90)
        case .detailed:
            return NSSize(width: 340, height: 180)
        }
    }

    func setPosition(_ position: WidgetPosition) {
        widgetPosition = position
        guard let window = widgetWindow, let screen = NSScreen.main else { return }
        let size = widgetSizeForStyle(widgetStyle)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame(for: size, on: screen), display: true)
        }
    }

    func setStyle(_ style: WidgetStyle) {
        widgetStyle = style

        // Recreate window with new style
        let wasVisible = isVisible
        if wasVisible {
            widgetWindow?.orderOut(nil)
        }
        widgetWindow = nil
        hasDelegated = false

        if wasVisible {
            showWidget()
        }
    }

    func setWidgetType(_ type: WidgetType) {
        widgetType = type

        // Recreate window with new type
        let wasVisible = isVisible
        if wasVisible {
            widgetWindow?.orderOut(nil)
        }
        widgetWindow = nil
        hasDelegated = false

        if wasVisible {
            showWidget()
        }
    }

    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}

// MARK: - Widget Container View

struct WidgetContainerView: View {
    let type: WidgetWindowController.WidgetType
    let style: WidgetWindowController.WidgetStyle
    @ObservedObject var weatherProvider: WeatherProvider
    @ObservedObject var activityProvider: ActivityProvider

    var body: some View {
        Group {
            switch type {
            case .weather:
                switch style {
                case .standard:
                    WeatherWidget(weatherProvider: weatherProvider)
                case .compact:
                    CompactWeatherWidget(weatherProvider: weatherProvider)
                case .circular:
                    CircularWeatherWidget(weatherProvider: weatherProvider)
                case .detailed:
                    DetailedWeatherWidget(weatherProvider: weatherProvider)
                }
            case .activity:
                switch style {
                case .standard:
                    ActivityWidget(activityProvider: activityProvider)
                case .compact:
                    CompactActivityWidget(activityProvider: activityProvider)
                case .circular:
                    CircularActivityWidget(activityProvider: activityProvider)
                case .detailed:
                    DetailedActivityWidget(activityProvider: activityProvider)
                }
            }
        }
    }
}
