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

@objc class LibraryPickerObjCBridge: NSObject {
    @objc class func makeLibraryPickerWindow() -> NSWindowController {
        SwiftUIWindowController(rootView: LibraryPickerWindow(library: LibraryDirectories()), title: "Select Main Photo Folder(s)")
    }
}
