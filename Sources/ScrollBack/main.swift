import AppKit

// LSUIElement in Info.plist already keeps the app out of the Dock; setting the
// activation policy here too means it still behaves when run loose, outside
// the bundle (e.g. `swift run` during development).
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
