import AppKit
import SwiftUI

// MARK: - Topmost Window (Lock Screen Compatible)

class TopmostWindow: NSWindow {
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: backing,
            defer: flag
        )

        isOpaque = false
        alphaValue = 1
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = NSColor.clear
        isMovable = false
        collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        hasShadow = false
        canBecomeVisibleWithoutLogin = true  // KEY: Allows window on lock screen
        level = .init(rawValue: .init(Int32.max - 2))  // Very high level
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - SkyLight Operator

class SkyLightOperator {
    static let shared = SkyLightOperator()

    // SkyLight function types
    private typealias SLSMainConnectionIDFunc = @convention(c) () -> UInt32
    private typealias SLSSpaceCreateFunc = @convention(c) (UInt32, UInt64, CFDictionary?) -> UInt64
    private typealias SLSSpaceSetAbsoluteLevelFunc = @convention(c) (UInt32, UInt64, Int32) -> Void
    private typealias SLSShowSpacesFunc = @convention(c) (UInt32, CFArray, UInt32) -> Void
    private typealias SLSSpaceAddWindowsFunc = @convention(c) (UInt32, UInt64, CFArray, UInt32) -> Void

    // Function pointers
    private var mainConnectionID: SLSMainConnectionIDFunc?
    private var spaceCreate: SLSSpaceCreateFunc?
    private var spaceSetAbsoluteLevel: SLSSpaceSetAbsoluteLevelFunc?
    private var showSpaces: SLSShowSpacesFunc?
    private var spaceAddWindows: SLSSpaceAddWindowsFunc?

    private var connectionID: UInt32 = 0
    private var spaceID: UInt64 = 0
    private var isLoaded = false

    // Space level for lock screen (NotificationCenterAtScreenLock = 400)
    private let lockScreenSpaceLevel: Int32 = 400

    private init() {
        loadSkyLight()
    }

    private func loadSkyLight() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_NOW) else {
            print("[SkyLight] Failed to load framework")
            return
        }

        // Load function pointers
        if let sym = dlsym(handle, "SLSMainConnectionID") {
            mainConnectionID = unsafeBitCast(sym, to: SLSMainConnectionIDFunc.self)
        }

        if let sym = dlsym(handle, "SLSSpaceCreate") {
            spaceCreate = unsafeBitCast(sym, to: SLSSpaceCreateFunc.self)
        }

        if let sym = dlsym(handle, "SLSSpaceSetAbsoluteLevel") {
            spaceSetAbsoluteLevel = unsafeBitCast(sym, to: SLSSpaceSetAbsoluteLevelFunc.self)
        }

        if let sym = dlsym(handle, "SLSShowSpaces") {
            showSpaces = unsafeBitCast(sym, to: SLSShowSpacesFunc.self)
        }

        if let sym = dlsym(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces") {
            spaceAddWindows = unsafeBitCast(sym, to: SLSSpaceAddWindowsFunc.self)
        }

        // Initialize
        guard let getConnectionID = mainConnectionID,
              let createSpace = spaceCreate,
              let setLevel = spaceSetAbsoluteLevel,
              let show = showSpaces else {
            print("[SkyLight] Failed to load required functions")
            return
        }

        connectionID = getConnectionID()
        print("[SkyLight] Connection ID: \(connectionID)")

        // Create space at lock screen level
        spaceID = createSpace(connectionID, 1, nil)
        print("[SkyLight] Created space ID: \(spaceID)")

        setLevel(connectionID, spaceID, lockScreenSpaceLevel)
        print("[SkyLight] Set space level to \(lockScreenSpaceLevel)")

        show(connectionID, [spaceID] as CFArray, 0)
        print("[SkyLight] Space is now visible")

        isLoaded = true
    }

    func delegateWindow(_ window: NSWindow) {
        guard isLoaded, let addWindows = spaceAddWindows else {
            print("[SkyLight] Cannot delegate window - not loaded")
            return
        }

        let windowID = window.windowNumber
        guard windowID > 0 else {
            print("[SkyLight] Invalid window number")
            return
        }

        addWindows(connectionID, spaceID, [windowID] as CFArray, 0x7)
        print("[SkyLight] Delegated window \(windowID) to space \(spaceID)")
    }
}
