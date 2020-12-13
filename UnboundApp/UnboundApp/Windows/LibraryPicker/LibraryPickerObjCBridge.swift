import Cocoa
import SwiftUI

class SwiftUIWindowController<RootView: View>: NSWindowController {
    convenience init(rootView: RootView) {
        let hostingController = NSHostingController(rootView: rootView.frame(width: 400, height: 300))
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 300))
        self.init(window: window)
    }
}

@objc class LibraryPickerObjCBridge: NSView {
    @objc class func makeLibraryPicker() -> NSWindowController {
        SwiftUIWindowController(rootView: LibraryPicker())
    }
}
