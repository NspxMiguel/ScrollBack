import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Defaults.registerDefaults()
        NSApp.setActivationPolicy(.accessory)

        statusItemController = StatusItemController()

        if !Permissions.isAccessibilityTrusted {
            Permissions.promptForAccessibility()
        }

        ScrollInverter.shared.start()
        SideButtonReviver.shared.start()

        Log.write("ScrollBack started — accessibility: \(Permissions.isAccessibilityTrusted ? "yes" : "NO")")
    }

    func applicationWillTerminate(_ notification: Notification) {
        ScrollInverter.shared.stop()
        SideButtonReviver.shared.stop()
    }
}
