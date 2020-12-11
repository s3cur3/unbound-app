//
// Created by Ryan Harter on 10/6/16.
// Copyright (c) 2016 Pixite Apps LLC. All rights reserved.
//

import AppKit
import Foundation

class PIXAboutWindowController: NSWindowController {
    @IBOutlet var icon: NSImageView!
    @IBOutlet var title: NSTextField!
    @IBOutlet var version: NSTextField!
    @IBOutlet var copyright: NSTextField!
    @IBOutlet var link: NSButton!
    @IBOutlet var logo: NSImageView!

    fileprivate var url: String = ""

    convenience init() {
        self.init(windowNibName: "PIXAboutWindowController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        icon.image = NSApp.applicationIconImage

        let infoDict = Bundle.main.infoDictionary!
        title.stringValue = infoDict["CFBundleName"] as! String

        let versionNumber = infoDict["CFBundleShortVersionString"] as! String
        let buildNumber = infoDict["CFBundleVersion"] as! String
        version.stringValue = "Version \(versionNumber) (\(buildNumber))"

        copyright.stringValue = infoDict["PIXCopyright"] as! String

        url = infoDict["PIXAppLink"] as! String
        link.title = url
    }

    @IBAction func onAppLinkClicked(_: AnyObject) {
        NSWorkspace.shared.open(URL(string: url)!)
    }

    override func keyDown(with theEvent: NSEvent) {
        if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command), theEvent.charactersIgnoringModifiers! == "w" {
            window?.close()
            return
        }
        super.keyUp(with: theEvent)
    }
}
