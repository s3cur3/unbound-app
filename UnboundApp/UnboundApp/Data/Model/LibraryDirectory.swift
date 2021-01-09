struct LibraryDirectory: Codable, Equatable, Identifiable {
    var path: URL
    var id: String

    init(withUrl url: URL) {
        path = url
        id = url.absoluteString
    }

    static func chooseFromSystemDialog(withExisting: [LibraryDirectory]) -> [LibraryDirectory] {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Select a Directory to Scan for Photos"

        if openPanel.runModal() == .OK, let url = openPanel.url {
            guard hasWriteAccess(url) || LibraryDirectory.userDGAFAboutWriteAccess()
            else {
                return []
            }

            guard url.startAccessingSecurityScopedResource() else {
                modalAlert(title: "Could Not Access Folder",
                           body: "Your Mac’s security settings prevented Unbound from accessing the folder you chose.")
                return []
            }

            // Reject if we already have this exact directory
            guard !withExisting.contains(LibraryDirectory(withUrl: url)) else {
                modalAlert(title: "Already Scanning Directory",
                           body: "Unbound is already set to scan \(formatForDisplay(url)).")
                return []
            }

            // Reject if the selected URL is a subdirectory of an existing one
            if let parent = withExisting.first(where: { pathHasAncestor(maybeChild: url, maybeAncestor: $0.path) }) {
                modalAlert(title: "Already Scanning Directory",
                           body: "Unbound is already set to scan \(formatForDisplay(parent.path)), which includes \(formatForDisplay(url)).")
                return []
            }

            // If any existing directory is a subdirectory the new one
            if let child = withExisting.first(where: { pathHasAncestor(maybeChild: $0.path, maybeAncestor: url) }) {
                modalAlert(title: "Cannot Add Parent Directory",
                           body: "Unbound is already set to scan \(formatForDisplay(child.path)). Remove that folder first before adding its parent directory \(formatForDisplay(url)).")
                return []
            }

            // Check if the user chose a dropbox folder where we should only use the Photos and Camera Uploads subfolders
            if url.lastPathComponent == "Dropbox" {
                let dropboxUrls = [url.appendingPathComponent("Photos"),
                                   url.appendingPathComponent("Camera Uploads")]
                if dropboxUrls.allSatisfy(directoryExistsAtPath) {
                    let alert = NSAlert()
                    alert.messageText = "Use Photos and Camera Uploads Folder?"
                    alert.informativeText = "You’ve selected your Dropbox folder for your photos. Would you like Unbound to scan just the Photos and Camera Uploads subfolders? This is a common usage."
                    alert.addButton(withTitle: "Use Just Photos & Camera Uploads")
                    alert.addButton(withTitle: "Use Entire Dropbox")
                    if alert.runModal() == .alertFirstButtonReturn {
                        return dropboxUrls.map { LibraryDirectory(withUrl: $0) }
                    }
                }
            }
            return [LibraryDirectory(withUrl: url)]
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

@objc class LibraryDirectoryObjCBridge: NSObject {
    @objc class func chooseFromSystemDialog(existing: LibraryDirectoriesObjCBridge) -> [Any] {
        LibraryDirectory.chooseFromSystemDialog(withExisting: existing.lib.directories)
    }
}
