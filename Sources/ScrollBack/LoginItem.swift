import ServiceManagement

enum LoginItem {
    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            Log.error("login item: \(error.localizedDescription)")
            return false
        }
    }
}
