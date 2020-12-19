//
// Created by Ryan Harter on 3/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa
import Foundation
import StoreKit

@objc class MainWindowController: NSWindowController {
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

        setAppearanceFromPrefs()
        maybeSolicitReview()
    }

    override func keyDown(with event: NSEvent) {
        if event.isCommandW() {
            close()
            return
        }
        super.keyDown(with: event)
    }

    @objc func wantDarkMode() -> Bool {
        if defaults.object(forKey: "backgroundTheme") != nil {
            return defaults.integer(forKey: "backgroundTheme") != 0
        } else {
            if #available(OSX 10.14, *) {
                return NSApp.appearance == NSAppearance(named: .darkAqua)
            } else {
                return false
            }
        }
    }

    func setAppearanceFromPrefs() {
        if #available(OSX 10.14, *) {
            NSApp.appearance = NSAppearance(named: wantDarkMode() ? .darkAqua : .aqua)
        }
    }

    private func maybeSolicitReview() {
        // If we showed the embarassing "the app crashed, wanna reset?" dialog,
        // don't count this toward our happy launches, and don't also immediately ask for a review
        if !defaults.bool(forKey: kAppShowedCrashDialog) {
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
}
