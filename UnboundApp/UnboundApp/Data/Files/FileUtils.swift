

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
