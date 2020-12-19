//
// Created by Ryan Harter on 6/7/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa
import CoreServices

struct AppInfo {
    let name: String?
    let version: String?
    let path: URL
    let isSystemDefault: Bool
}

class SystemAppHelper {
    class func editorAppsForFileUrl(path: URL) -> [AppInfo] {
        let apps = LSCopyApplicationURLsForURL(path as CFURL, .editor)!.takeRetainedValue() as? [URL] ?? []
        let defaultApp = LSCopyDefaultApplicationURLForURL(path as CFURL, .editor, nil)?.takeRetainedValue() as URL?

        return apps.map { url in
            AppInfo(
                name: try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName,
                version: Bundle(url: url)?.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String,
                path: url,
                isSystemDefault: url == defaultApp
            )
        }
    }

    class func nameForAppUrl(path: URL) -> String? {
        Bundle(url: path)?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }

    class func versionForAppUrl(path: URL) -> String? {
        Bundle(url: path)?.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
}
