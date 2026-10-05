import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var retryTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Defaults.registerDefaults()
        NSApp.setActivationPolicy(.accessory)

        statusItemController = StatusItemController()

        if !Permissions.isAccessibilityTrusted {
            Permissions.promptForAccessibility()
        }
        Permissions.requestInputMonitoring()

        startServices()
        Log.write("ScrollBack started — accessibility: \(Permissions.isAccessibilityTrusted ? "yes" : "NO")")

        // Permissions are granted in System Settings while the app is already
        // running. Without this, granting them did nothing until a relaunch,
        // and the app looked broken.
        if !servicesRunning {
            retryTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
                guard let self else { return timer.invalidate() }
                self.startServices()
                if self.servicesRunning {
                    Log.write("ScrollBack: permissions granted, scroll and side buttons active")
                    timer.invalidate()
                }
            }
        }
    }

    private var servicesRunning: Bool {
        ScrollInverter.shared.isRunning && SideButtonReviver.shared.isRunning
    }

    private func startServices() {
        ScrollInverter.shared.start()
        SideButtonReviver.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        retryTimer?.invalidate()
        ScrollInverter.shared.stop()
        SideButtonReviver.shared.stop()
    }
}
