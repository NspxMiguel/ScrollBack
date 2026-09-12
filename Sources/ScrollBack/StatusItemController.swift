import AppKit

final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let invertItem = NSMenuItem()
    private let reviveItem = NSMenuItem()
    private let launchItem = NSMenuItem()
    private let permissionItem = NSMenuItem()

    override init() {
        super.init()
        configureButton()
        configureMenu()
    }

    private func configureButton() {
        let image = NSImage(
            systemSymbolName: "computermouse",
            accessibilityDescription: "ScrollBack"
        )
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.delegate = self

        invertItem.title = "Reverse scroll (mouse only)"
        invertItem.action = #selector(toggleInvert)
        invertItem.target = self
        menu.addItem(invertItem)

        reviveItem.title = "Enable side buttons (back / forward)"
        reviveItem.action = #selector(toggleRevive)
        reviveItem.target = self
        menu.addItem(reviveItem)

        menu.addItem(.separator())

        launchItem.title = "Start at login"
        launchItem.action = #selector(toggleLaunchAtLogin)
        launchItem.target = self
        menu.addItem(launchItem)

        menu.addItem(.separator())

        permissionItem.title = "Grant Accessibility permission…"
        permissionItem.action = #selector(openAccessibilityPrompt)
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ScrollBack", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        invertItem.state = Defaults.invertMouseScroll ? .on : .off
        reviveItem.state = Defaults.reviveSideButtons ? .on : .off
        launchItem.state = Defaults.launchAtLogin ? .on : .off
        permissionItem.isHidden = Permissions.isAccessibilityTrusted
    }

    @objc private func toggleInvert() {
        Defaults.invertMouseScroll.toggle()
    }

    @objc private func toggleRevive() {
        Defaults.reviveSideButtons.toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        let wanted = !Defaults.launchAtLogin
        if LoginItem.set(wanted) {
            Defaults.launchAtLogin = wanted
        }
    }

    @objc private func openAccessibilityPrompt() {
        Permissions.promptForAccessibility()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
