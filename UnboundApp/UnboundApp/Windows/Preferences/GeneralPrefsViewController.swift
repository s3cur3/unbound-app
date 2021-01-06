//
// Created by Ryan Harter on 3/13/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import CoreServices
import Foundation
import SwiftUI

class GeneralPrefsViewController: NSViewController, MASPreferencesViewController {
    private var defaults = UserDefaults.standard

    @IBOutlet var defaultEditorButton: NSPopUpButton?
    @IBOutlet var libraryPickerView: NSView!

    private var editorApps: [AppInfo]?

    // MARK: - MASPreferencesViewController

    private(set) var viewIdentifier: String = "General"
    private(set) var toolbarItemLabel: String? = NSLocalizedString("preferences.general.title", comment: "General")
    private(set) var toolbarItemImage: NSImage? = NSImage(named: NSImage.preferencesGeneralName)

    override func viewDidLoad() {
        super.viewDidLoad()
        updateEditors()

        let childView = NSHostingController(rootView: LibraryPickerForPrefs())
        addChild(childView)
        childView.view.frame = libraryPickerView.bounds
        libraryPickerView.addSubview(childView.view)
    }

    private func updateEditors() {
        guard let button = defaultEditorButton, let imageUrl = Bundle.main.pathForImageResource("temp") else {
            return
        }

        editorApps = SystemAppHelper.editorAppsForFileUrl(path: URL(fileURLWithPath: imageUrl))
            .filter { info in
                info.name != nil
            }
            .sorted { first, _ in
                first.isSystemDefault
            }

        button.menu?.removeAllItems()

        let defaultPath: String? = defaults[prefDefaultEditorPath] as? String
        var names = [String]()
        for (i, info) in editorApps!.enumerated() {
            var name: String
            if names.contains(info.name!) {
                guard let version = info.version else {
                    return
                }
                name = "\(info.name!) (\(version))"
            } else {
                name = info.name!
            }

            if info.isSystemDefault {
                name = "\(name) (System Default)"
            }

            let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            item.tag = i
            button.menu?.addItem(item)
            names.append(info.name!)

            if (defaultPath == nil && info.isSystemDefault) || info.path.absoluteString == defaultPath {
                button.selectItem(withTitle: name)
            }
        }

        if editorApps!.count > 2 {
            button.menu?.insertItem(NSMenuItem.separator(), at: 1)
        }
    }

    // MARK: - IBActions

    @IBAction func setDefaultEditor(sender: NSPopUpButton) {
        guard let index = sender.selectedItem?.tag, let item = editorApps?[index] else {
            return
        }

        defaults[prefDefaultEditorPath] = item.path.absoluteString
        defaults[prefDefaultEditorName] = item.name
    }

    @IBAction func resetAlerts(sender _: NSButton) {
        defaults[kPrefSupressDeleteWarning] = false
        defaults[kPrefSupressAlbumDeleteWarning] = false
    }
}
