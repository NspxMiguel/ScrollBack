import ApplicationServices
import Foundation

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
}
