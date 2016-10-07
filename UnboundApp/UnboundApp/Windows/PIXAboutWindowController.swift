//
// Created by Ryan Harter on 10/6/16.
// Copyright (c) 2016 Pixite Apps LLC. All rights reserved.
//

import Foundation
import AppKit

class PIXAboutWindowController: NSWindowController {

    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var copyright: NSTextField!
    @IBOutlet weak var link: NSButton!
    @IBOutlet weak var logo: NSImageView!

    private var url: String = ""

    convenience init() {
        self.init(windowNibName: "PIXAboutWindowController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        icon.image = NSApp.applicationIconImage

        let infoDict = NSBundle.mainBundle().infoDictionary!
        title.stringValue = infoDict["CFBundleName"] as! String

        let versionNumber = infoDict["CFBundleShortVersionString"] as! String
        let buildNumber = infoDict["CFBundleVersion"] as! String
        version.stringValue = "Version \(versionNumber) (\(buildNumber))"

        copyright.stringValue = infoDict["PIXCopyright"] as! String

        url = infoDict["PIXAppLink"] as! String

        let center = NSMutableParagraphStyle()
        center.alignment = NSCenterTextAlignment
        let attributes = [
                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                NSForegroundColorAttributeName: NSColor.blueColor(),
                NSParagraphStyleAttributeName: center
        ]
        link.attributedTitle = NSAttributedString(string: url, attributes: attributes)
    }

    @IBAction func onAppLinkClicked(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!)
    }

    override func keyDown(theEvent: NSEvent) {
        if theEvent.modifierFlags.contains(.CommandKeyMask) && theEvent.charactersIgnoringModifiers! == "w" {
            self.window?.close()
            return
        }
        super.keyUp(theEvent)
    }

}