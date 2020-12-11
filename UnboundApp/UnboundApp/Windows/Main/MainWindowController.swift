//
// Created by Ryan Harter on 3/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa
import Foundation
import StoreKit

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

        maybeSolicitReview()
    }

    override func keyDown(with event: NSEvent) {
        if event.isCommandW() {
            close()
            return
        }
        super.keyDown(with: event)
    }

    private func maybeSolicitReview() {
        let launchCount = defaults.integer(forKey: prefLaunchCount) + 1
        defaults.set(launchCount, forKey: prefLaunchCount)

        #if !TRIAL
            if #available(OSX 10.14, *) {
                if launchCount >= 10 {
                    SKStoreReviewController.requestReview()
                }
            }
        #endif // !TRIAL
    }
}
