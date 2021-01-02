

func directoryExistsAtPath(_ path: URL) -> Bool {
    var isDirectory = ObjCBool(true)
    let exists = FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}

func hasWriteAccess(_ path: URL) -> Bool {
    FileManager.default.isWritableFile(atPath: path.path)
}
