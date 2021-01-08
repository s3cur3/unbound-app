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
    @objc class func makeLibraryPickerWindow(withLib: LibraryDirectoriesObjCBridge) -> NSWindowController {
        SwiftUIWindowController(rootView: LibraryPickerWindow(library: withLib.lib), title: "Select Main Photo Folder(s)")
    }

    @objc class func makeLibraryPickerForFirstRun(withLib _: LibraryDirectoriesObjCBridge) -> NSViewController {
        // TODO: the 16px top padding here is a horrifying hack to work around a SwiftUI bug where the top of our list is getting cut off
        NSHostingController(rootView: LibraryPicker(library: PIXAppDelegate.shared()!.libraryDirs.lib, topPadding: 16))
    }
}
