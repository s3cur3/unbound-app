//
// Created by Ryan Harter on 3/13/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

class AppearancePrefsViewController: NSViewController, MASPreferencesViewController {

  private(set) var viewIdentifier: String = "Appearance"
  private(set) var toolbarItemLabel: String? = NSLocalizedString("preferences.interface.title", comment: "Appearance")
  private(set) var toolbarItemImage: NSImage? = NSImage(named: NSImage.colorPanelName)

  //MARK - IBActions

  @IBAction func themeChanged(sender: Any) {
    // the user default (@"backgroundTheme") is changed through a binding. We just need to send out the notification
    NotificationCenter.default.post(name: Notification.Name("backgroundThemeChanged"), object: nil)
  }

  @IBAction func photoStyleChanged(sender: Any) {
    NotificationCenter.default.post(name: Notification.Name(kNotePhotoStyleChanged), object: nil)
  }

}
