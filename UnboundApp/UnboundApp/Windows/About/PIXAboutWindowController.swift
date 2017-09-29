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

    fileprivate var url: String = ""

    convenience init() {
        self.init(windowNibName: NSNib.Name(rawValue: "PIXAboutWindowController"))
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

        let center = NSMutableParagraphStyle()
        center.alignment = .center
        let attributes = [
                .underlineStyle: NSUnderlineStyle.styleSingle,
                .foregroundColor: NSColor.blue,
                .paragraphStyle: center
            ] as [NSAttributedStringKey : Any]
        link.attributedTitle = NSAttributedString(string: url, attributes: attributes)
    }

    @IBAction func onAppLinkClicked(_ sender: AnyObject) {
        NSWorkspace.shared.open(URL(string: url)!)
    }

    override func keyDown(with theEvent: NSEvent) {
        if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command) && theEvent.charactersIgnoringModifiers! == "w" {
            self.window?.close()
            return
        }
        super.keyUp(with: theEvent)
    }

}
