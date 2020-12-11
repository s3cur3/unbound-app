//
// Created by Ryan Harter on 3/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa
import Foundation

@objc class ThemedWindow: NSWindowController {
    override func windowWillLoad() {
        super.windowWillLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ThemedWindow.themeChanged),
                                               name: Notification.Name("backgroundTheme"),
                                               object: nil)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // TODO: implement theming
//    self.window?.titlebarAppearsTransparent = true
//    self.window?.backgroundColor = NSColor.darkGray
    }

    @objc func themeChanged() {
        window?.backgroundColor = NSColor.darkGray
    }
}
