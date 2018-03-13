//
// Created by Ryan Harter on 3/13/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

@objc class PreferencesWindowController: MASPreferencesWindowController {

  @objc class func create() -> PreferencesWindowController {
    let title = NSLocalizedString("preferences.window.title", comment: "Preferences window title")
    let controllers = [
      GeneralPrefsViewController(),
      AppearancePrefsViewController()
    ];

    return PreferencesWindowController(viewControllers: controllers, title: title)
  }

  override func keyDown(with event: NSEvent) {
    if (event.isCommandW()) {
      self.close()
      return
    }
    super.keyDown(with: event)
  }
}
