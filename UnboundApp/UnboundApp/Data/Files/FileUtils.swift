

func directoryExistsAtPath(_ path: URL) -> Bool {
    var isDirectory = ObjCBool(true)
    let exists = FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}

func hasWriteAccess(_ path: URL) -> Bool {
    FileManager.default.isWritableFile(atPath: path.path)
}

func pathHasAncestor(maybeChild: URL, maybeAncestor: URL) -> Bool {
    let ancestorComponents: [String] = canonicalize(maybeAncestor).pathComponents
    let childComponents: [String] = canonicalize(maybeChild).pathComponents

    return ancestorComponents.count < childComponents.count
        && !zip(ancestorComponents, childComponents).contains(where: !=)
}

func canonicalize(_ url: URL) -> URL {
    url.standardizedFileURL.resolvingSymlinksInPath()
}

func formatForDisplay(_ url: URL) -> String {
    let components = url.pathComponents
    if components.count > 3 {
        if components.starts(with: ["/", "Users"]) {
            let shortened = ["~"] + components.dropFirst(3)
            return shortened.joined(separator: "/")
        } else if components.starts(with: ["/", "Volumes"]) {
            return components.dropFirst(3).joined(separator: "/")
        }
    } else if components.count == 3, components.starts(with: ["/", "Volumes"]) {
        return components.dropFirst(2).joined(separator: "/")
    }

    return url.path
}

@objc class FileUtilsBridge: NSObject {
    @objc class func formatUrlForDisplay(_ url: URL) -> String {
        formatForDisplay(url)
    }
}
