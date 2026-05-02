import Foundation
import Combine
import AppKit

// MARK: - Lock Screen Monitor

@MainActor
class LockScreenMonitor: NSObject, ObservableObject {
    static let shared = LockScreenMonitor()

    @Published private(set) var isScreenLocked = false

    override init() {
        super.init()
        setupNotificationObservers()
        print("[LockScreenMonitor] Initialized and listening for lock events")
    }

    private func setupNotificationObservers() {
        // Use direct observer pattern like Atoll does
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )

        // Also observe sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenDidSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    // MARK: - Event Handlers

    @objc private func screenDidLock() {
        print("[LockScreenMonitor] Screen LOCKED")
        Task { @MainActor in
            self.isScreenLocked = true
            NotificationCenter.default.post(name: .lockScreenDidActivate, object: nil)
        }
    }

    @objc private func screenDidUnlock() {
        print("[LockScreenMonitor] Screen UNLOCKED")
        Task { @MainActor in
            self.isScreenLocked = false
            NotificationCenter.default.post(name: .lockScreenDidDeactivate, object: nil)
        }
    }

    @objc private func screenDidSleep() {
        print("[LockScreenMonitor] Screen went to SLEEP")
    }

    @objc private func screenDidWake() {
        print("[LockScreenMonitor] Screen WOKE UP")
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let lockScreenDidActivate = Notification.Name("LockScreenDidActivate")
    static let lockScreenDidDeactivate = Notification.Name("LockScreenDidDeactivate")
    static let screenSaverDidStart = Notification.Name("ScreenSaverDidStart")
    static let screenSaverDidStop = Notification.Name("ScreenSaverDidStop")
    static let screensDidSleep = Notification.Name("ScreensDidSleep")
    static let screensDidWake = Notification.Name("ScreensDidWake")
}
