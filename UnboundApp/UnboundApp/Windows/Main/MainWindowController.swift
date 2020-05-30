//
// Created by Ryan Harter on 3/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation
import Cocoa

class MainWindowController: NSWindowController {

  @IBOutlet public weak var navigationViewController: NavigationController?
  public var albumViewController: PIXAlbumCollectionViewController?

  override func windowDidLoad() {
    super.windowDidLoad()

    let defaults = UserDefaults.standard
    if (defaults.bool(forKey: kAppObservedDirectoryUnavailable) &&
        !defaults.bool(forKey: kAppObservedDirectoryUnavailableSupressAlert) &&
        !defaults.bool(forKey: kAppFirstRun)) {
      PIXAppDelegate.shared().openAlert(kRootFolderUnavailableTitle, withMessage: kRootFolderUnavailableDetailMessage)
    }
    
    navigationViewController?.view.wantsLayer = true

    let albumController = PIXAlbumCollectionViewController(nibName: "PIXAlbumCollectionViewController", bundle: nil)
    self.albumViewController = albumController
    navigationViewController?.pushViewController(viewController: albumController)
  }

  override func keyDown(with event: NSEvent) {
    if (event.isCommandW()) {
      self.close()
      return
    }
    super.keyDown(with: event)
  }
}
