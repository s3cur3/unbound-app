//
// Created by Ryan Harter on 3/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa
import Foundation

class MainWindowController: NSWindowController {
    @IBOutlet public var navigationViewController: NavigationController?
    public var albumViewController: PIXAlbumCollectionViewController?

    private var defaults = UserDefaults.standard

    override func windowDidLoad() {
        super.windowDidLoad()

        let defaults = UserDefaults.standard
        if defaults.bool(forKey: kAppObservedDirectoryUnavailable) &&
            !defaults.bool(forKey: kAppObservedDirectoryUnavailableSupressAlert) &&
            !defaults.bool(forKey: kAppFirstRun)
        {
            PIXAppDelegate.shared().openAlert(kRootFolderUnavailableTitle, withMessage: kRootFolderUnavailableDetailMessage)
        }

        navigationViewController?.view.wantsLayer = true

        let albumController = PIXAlbumCollectionViewController(nibName: "PIXAlbumCollectionViewController", bundle: nil)
        albumViewController = albumController
        navigationViewController?.pushViewController(viewController: albumController)
    }

    override func keyDown(with event: NSEvent) {
        if event.isCommandW() {
            close()
            return
        }
        super.keyDown(with: event)
    }
}
