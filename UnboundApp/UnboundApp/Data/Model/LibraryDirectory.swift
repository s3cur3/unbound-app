struct LibraryDirectory: Codable, Equatable, Identifiable {
    var path: URL
    var id: String

    init(withUrl url: URL) {
        path = url
        id = url.absoluteString
    }

    static func chooseFromSystemDialog() -> [LibraryDirectory] {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Select a Directory to Scan for Photos"

        if openPanel.runModal() == .OK, openPanel.url != nil {
            guard hasWriteAccess(openPanel.url!) || LibraryDirectory.userDGAFAboutWriteAccess()
            else {
                return []
            }

            guard openPanel.url!.startAccessingSecurityScopedResource() else {
                modalAlert(title: "Could Not Access Folder",
                           body: "Your Mac’s security settings prevented Unbound from accessing the folder you chose.")
                return []
            }

            var out = [LibraryDirectory(withUrl: openPanel.url!)]

            // Check if the user chose a dropbox folder where we should only use the Photos and Camera Uploads subfolders
            if openPanel.url!.lastPathComponent == "Dropbox" {
                let dropboxUrls = [openPanel.url!.appendingPathComponent("Photos"),
                                   openPanel.url!.appendingPathComponent("Camera Uploads")]
                if dropboxUrls.allSatisfy(directoryExistsAtPath) {
                    let alert = NSAlert()
                    alert.messageText = "Use Photos and Camera Uploads Folder?"
                    alert.informativeText = "You’ve selected your Dropbox folder for your photos. Would you like Unbound to scan just the Photos and Camera Uploads subfolders? This is a common usage."
                    alert.addButton(withTitle: "Use Just Photos & Camera Uploads")
                    alert.addButton(withTitle: "Use Entire Dropbox")
                    if alert.runModal() == .alertFirstButtonReturn {
                        out = dropboxUrls.map { LibraryDirectory(withUrl: $0) }
                    }
                }
            }

            // App delegate showMainWindow?
            // fileparser stopObserving
            // fileparser setSandboxScopeURLs
            NSLog("TODO: File parser massaging?")

            openPanel.url!.stopAccessingSecurityScopedResource()

            // [[PIXAppDelegate sharedAppDelegate] clearDatabase]?
            // fileparser scanFullDirectory

            // for(NSURL * pathURL in self.observedDirectories)
            // {
            //     NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", pathURL.path];
            //     [[NSUserDefaults standardUserDefaults] removeObjectForKey:tokenKeyString];
            // }
            //
            // [self startObserving];
            //
            // [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];

            return out
        } else {
            return []
        }
    }

    static func userDGAFAboutWriteAccess() -> Bool {
        let result = cancellableAlert(title: "Write Permissions Are Required",
                                      body: "The folder you selected is read-only, which may prevent some app features from functioning properly. Scan this folder anyway?")
        return result == .OK
    }
}
