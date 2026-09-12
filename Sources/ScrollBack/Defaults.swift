import Foundation

enum Defaults {
    private static let store = UserDefaults.standard

    private enum Key {
        static let invertMouseScroll = "invertMouseScroll"
        static let reviveSideButtons = "reviveSideButtons"
        static let launchAtLogin = "launchAtLogin"
    }

    static func registerDefaults() {
        store.register(defaults: [
            Key.invertMouseScroll: true,
            Key.reviveSideButtons: true,
        ])
    }

    static var invertMouseScroll: Bool {
        get { store.bool(forKey: Key.invertMouseScroll) }
        set { store.set(newValue, forKey: Key.invertMouseScroll) }
    }

    static var reviveSideButtons: Bool {
        get { store.bool(forKey: Key.reviveSideButtons) }
        set { store.set(newValue, forKey: Key.reviveSideButtons) }
    }

    static var launchAtLogin: Bool {
        get { store.bool(forKey: Key.launchAtLogin) }
        set { store.set(newValue, forKey: Key.launchAtLogin) }
    }
}
