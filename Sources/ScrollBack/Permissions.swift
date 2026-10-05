import ApplicationServices
import Foundation
import IOKit.hid

enum Permissions {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system's own "ScrollBack wants to control this computer"
    /// prompt. Granting it is the user's own click in System Settings — this
    /// only opens the door, it never flips the switch itself.
    @discardableResult
    static func promptForAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Reading the mouse's raw HID reports (for the side buttons) needs Input
    /// Monitoring, a separate switch from Accessibility. This asks for it once;
    /// macOS only shows the prompt the first time.
    static func requestInputMonitoring() {
        if IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) != kIOHIDAccessTypeGranted {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }
    }
}
