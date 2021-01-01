import Cocoa
import SwiftUI

class SwiftUIWindowController<RootView: View>: NSWindowController {
    convenience init(rootView: RootView, title: String) {
        let hostingController = NSHostingController(rootView: rootView.frame(width: 400, height: 300))
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 300))
        window.title = title
        self.init(window: window)
    }
}

@objc class LibraryPickerObjCBridge: NSView {
    @objc class func makeLibraryPicker() -> NSWindowController {
        // TODO: pull dirs from prefs
        SwiftUIWindowController(rootView: LibraryPicker(), title: "Select Main Photo Folder(s)")
    }
}
