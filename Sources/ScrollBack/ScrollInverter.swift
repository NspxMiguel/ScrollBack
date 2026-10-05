import CoreGraphics
import Foundation

/// Flips the vertical (and tilt-wheel horizontal) scroll direction, but only
/// for events that came from a physical mouse wheel. Trackpads and Magic
/// Mice report scrolling as "continuous" (pixel-precise momentum); a mouse
/// with a real notched wheel reports "line" scrolling. That single field is
/// what lets one machine-wide setting invert the mouse without ever touching
/// the trackpad — the same trick the open-source Scroll Reverser app uses.
final class ScrollInverter {
    static let shared = ScrollInverter()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    func start() {
        guard eventTap == nil else { return }

        let mask: CGEventMask = 1 << CGEventType.scrollWheel.rawValue
        let context = Unmanaged.passUnretained(self).toOpaque()

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: { proxy, type, event, refcon in
                    guard let refcon else { return Unmanaged.passUnretained(event) }
                    let inverter = Unmanaged<ScrollInverter>.fromOpaque(refcon).takeUnretainedValue()
                    return inverter.handle(proxy: proxy, type: type, event: event)
                },
                userInfo: context
            )
        else {
            Log.errorOnce("scroll: failed to create event tap — is Accessibility granted?")
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    var isRunning: Bool { eventTap != nil }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The system disables a tap that takes too long or gets flagged as
        // suspicious; re-enabling here is what keeps scrolling from silently
        // going back to normal until the next relaunch.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .scrollWheel, Defaults.invertMouseScroll else {
            return Unmanaged.passUnretained(event)
        }

        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        guard isContinuous == 0 else {
            // Trackpad or Magic Mouse — leave it exactly as it is.
            return Unmanaged.passUnretained(event)
        }

        for field: CGEventField in [.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2] {
            let value = event.getIntegerValueField(field)
            if value != 0 { event.setIntegerValueField(field, value: -value) }
        }
        for field: CGEventField in [.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2] {
            let value = event.getIntegerValueField(field)
            if value != 0 { event.setIntegerValueField(field, value: -value) }
        }
        let fixedAxis1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        if fixedAxis1 != 0 {
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedAxis1)
        }
        let fixedAxis2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        if fixedAxis2 != 0 {
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fixedAxis2)
        }

        return Unmanaged.passUnretained(event)
    }
}
