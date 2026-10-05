import CoreGraphics
import Foundation
import IOKit.hid

/// Some mice ship a 4th/5th button (back/forward) whose HID report never
/// turns into an AppKit mouse event — the click happens in hardware but
/// macOS's generic HID driver drops it on the floor. This watches the raw
/// HID report with IOHIDManager, and only when the same press does NOT show
/// up as a real CGEvent within a short window, synthesizes the button press
/// itself. If the system already delivers it natively, this gets out of the
/// way — the alternative would be a double back/forward on every click.
final class SideButtonReviver {
    static let shared = SideButtonReviver()

    private var hidManager: IOHIDManager?
    private var verifyTap: CFMachPort?
    private var verifyRunLoopSource: CFRunLoopSource?

    private var pendingButton: CGMouseButton?
    private var pendingGeneration = 0

    private init() {}

    func start() {
        startHIDMonitor()
        startVerifyTap()
    }

    /// True once both the raw HID monitor and the verify tap are live.
    var isRunning: Bool { hidManager != nil && verifyTap != nil }

    func stop() {
        stopHIDMonitor()
        stopVerifyTap()
    }

    // MARK: - Raw HID side: sees button presses even when AppKit never does

    private func startHIDMonitor() {
        guard hidManager == nil else { return }
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        let mouseMatch: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse,
        ]
        let pointerMatch: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Pointer,
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, [mouseMatch, pointerMatch] as CFArray)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterInputValueCallback(
            manager,
            { context, _, _, value in
                guard let context else { return }
                Unmanaged<SideButtonReviver>.fromOpaque(context).takeUnretainedValue()
                    .handleHIDValue(value)
            },
            context
        )

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            // Usually Input Monitoring not granted yet. Drop the manager so the
            // next start() retries instead of keeping a dead one forever.
            Log.errorOnce("side buttons: IOHIDManagerOpen failed (\(result))")
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            return
        }
        hidManager = manager
    }

    private func stopHIDMonitor() {
        guard let manager = hidManager else { return }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        hidManager = nil
    }

    private func handleHIDValue(_ value: IOHIDValue) {
        guard Defaults.reviveSideButtons else { return }
        let element = IOHIDValueGetElement(value)
        guard IOHIDElementGetUsagePage(element) == UInt32(kHIDPage_Button) else { return }

        // HID button usages are 1-indexed (1=left, 2=right, 3=middle); 4 and 5
        // are the side buttons most mice use for back/forward.
        let usage = IOHIDElementGetUsage(element)
        guard usage == 4 || usage == 5 else { return }
        guard IOHIDValueGetIntegerValue(value) != 0 else { return }

        // CGMouseButton is 0-indexed, so HID button 4 → rawValue 3, and 5 → 4.
        arm(CGMouseButton(rawValue: usage == 4 ? 3 : 4)!)
    }

    /// Gives the system ~25ms to turn the same physical press into a real
    /// CGEvent before this synthesizes one — long enough for the native path
    /// to win the race when it exists, short enough that nobody notices.
    private func arm(_ button: CGMouseButton) {
        pendingButton = button
        pendingGeneration += 1
        let generation = pendingGeneration

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) { [weak self] in
            guard let self, self.pendingGeneration == generation, self.pendingButton == button else { return }
            self.pendingButton = nil
            self.synthesize(button)
        }
    }

    private func synthesize(_ button: CGMouseButton) {
        let location = CGEvent(source: nil)?.location ?? .zero
        for type: CGEventType in [.otherMouseDown, .otherMouseUp] {
            guard
                let event = CGEvent(
                    mouseEventSource: nil,
                    mouseType: type,
                    mouseCursorPosition: location,
                    mouseButton: button
                )
            else { continue }
            event.post(tap: .cgSessionEventTap)
        }
    }

    // MARK: - Verification tap: cancels the synth if the system already delivered it

    private func startVerifyTap() {
        guard verifyTap == nil else { return }
        let mask: CGEventMask = 1 << CGEventType.otherMouseDown.rawValue
        let context = Unmanaged.passUnretained(self).toOpaque()

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: mask,
                callback: { _, type, event, refcon in
                    if type == .otherMouseDown, let refcon {
                        Unmanaged<SideButtonReviver>.fromOpaque(refcon).takeUnretainedValue()
                            .cancelPendingIfMatches(event)
                    }
                    return Unmanaged.passUnretained(event)
                },
                userInfo: context
            )
        else {
            Log.errorOnce("side buttons: failed to create verification tap")
            return
        }

        verifyTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        verifyRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func stopVerifyTap() {
        guard let tap = verifyTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = verifyRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        verifyTap = nil
        verifyRunLoopSource = nil
    }

    private func cancelPendingIfMatches(_ event: CGEvent) {
        guard let pending = pendingButton else { return }
        let number = event.getIntegerValueField(.mouseEventButtonNumber)
        if CGMouseButton(rawValue: UInt32(number)) == pending {
            pendingButton = nil
        }
    }
}
