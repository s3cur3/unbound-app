//
// Created by Ryan Harter on 3/13/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation
import CoreServices

class GeneralPrefsViewController: NSViewController, MASPreferencesViewController {

  private var defaults = UserDefaults.standard

  @IBOutlet weak var dbFolderButton: NSButton?
  @IBOutlet weak var folderDisplay: NSPathControl?
  @IBOutlet weak var workingSpinner: NSProgressIndicator?
  @IBOutlet weak var defaultEditorButton: NSPopUpButton?

  private var editorApps: [AppInfo]?

  //MARK - MASPreferencesViewController
  private(set) var viewIdentifier: String = "General"
  private(set) var toolbarItemLabel: String? = NSLocalizedString("preferences.general.title", comment: "General")
  private(set) var toolbarItemImage: NSImage? = NSImage(named: .preferencesGeneral)

  override func viewDidLoad() {
    super.viewDidLoad()
    updateFolderField()
    updateEditors()
  }

  private func updateFolderField() {
    let urls = PIXFileParser.shared().observedDirectories
    if (urls == nil || urls!.isEmpty) {
      self.folderDisplay?.url = nil
    } else {
      self.folderDisplay?.url = urls![0]
    }
  }

  private func updateEditors() {
    guard let button = self.defaultEditorButton,
          let imageUrl = Bundle.main.pathForImageResource(NSImage.Name(rawValue: "temp"))
        else {
      return
    }

    self.editorApps = SystemAppHelper.editorAppsForFileUrl(path: URL(fileURLWithPath: imageUrl))
        .filter { info in
          info.name != nil
        }
        .sorted { first, second in
          first.isSystemDefault
        }

    button.menu?.removeAllItems()

    let defaultPath: String? = defaults[prefDefaultEditorPath] as? String
    var names = [String]()
    self.editorApps!
        .forEachIndexed { info, i in
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

    if self.editorApps!.count > 2 {
      button.menu?.insertItem(NSMenuItem.separator(), at: 1)
    }

  }

  //MARK - IBActions

  @IBAction func chooseFolder(sender: NSButton) {
    PIXFileParser.shared().userChooseFolderDialog()
    updateFolderField()
  }

  @IBAction func reloadFiles(sender: NSButton) {
    PIXFileParser.shared().rescanFiles()
  }

  @IBAction func setDefaultEditor(sender: NSPopUpButton) {
    guard let index = sender.selectedItem?.tag,
          let item = self.editorApps?[index]
        else { return }

    defaults[prefDefaultEditorPath] = item.path.absoluteString
    defaults[prefDefaultEditorName] = item.name
  }

  @IBAction func resetAlerts(sender: NSButton) {
    defaults[kPrefSupressDeleteWarning] = false
    defaults[kPrefSupressAlbumDeleteWarning] = false
  }

}
