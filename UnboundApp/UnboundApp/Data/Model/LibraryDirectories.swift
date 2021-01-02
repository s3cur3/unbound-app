import Combine
import Foundation

class LibraryDirectories: ObservableObject {
    @Published var directories: [LibraryDirectory] {
        didSet {
            let existingDirectories = directories.compactMap { directoryExistsAtPath($0.path) ? $0.path : nil }
            let bookmarks = existingDirectories.compactMap(LibraryDirectories.makeBookmark)
            UserDefaults.standard.set(bookmarks, forKey: prefObservedDirectories)
            NotificationCenter.default.post(name: Notification.Name(kAppObservedDirectoriesChanged), object: nil)
        }
    }

    init() {
        directories = LibraryDirectories.fromPrefs()
    }

    init(withDirectories: [LibraryDirectory]) {
        directories = withDirectories
    }

    func remove(_ dir: LibraryDirectory) {
        directories = directories.filter { $0 != dir }
    }

    func add(_ dirs: [LibraryDirectory]) {
        if !dirs.isEmpty {
            directories = directories + dirs
        }
    }

    class func urlsFromPrefs() -> [URL] {
        bookmarksFromPrefs().compactMap(LibraryDirectories.toURL)
    }

    class func fromPrefs() -> [LibraryDirectory] {
        bookmarksFromPrefs()
            .compactMap(LibraryDirectories.toURL)
            .map { LibraryDirectory(withUrl: $0) }
    }

    fileprivate class func makeBookmark(_ path: URL) -> Data? {
        do {
            let bookmark = try path.bookmarkData()
            return bookmark
        } catch {
            NSLog("Error creating security-scoped bookmark \(path)")
            return nil
        }
    }

    fileprivate class func toURL(_ bookmark: Data) -> URL? {
        var isStale = Bool(false)
        do {
            let url = try URL(resolvingBookmarkData: bookmark, relativeTo: nil, bookmarkDataIsStale: &isStale)
            return url
        } catch {
            NSLog("Error creating url from saved bookmark \(bookmark). Stale? \(isStale)")
            return nil
        }
    }

    class func bookmarksFromPrefs() -> [Data] {
        UserDefaults.standard.object(forKey: prefObservedDirectories) as? [Data] ?? []
    }
}

@objc class LibraryDirectoriesObjCBridge: NSObject {
    @objc class func libraryUrlsFromPrefs() -> [URL] {
        LibraryDirectories.urlsFromPrefs()
    }

    @objc class func diffNewlyAdded(latestPrefs: [URL], previous: [URL]) -> [URL] {
        latestPrefs.filter { !previous.contains($0) }
    }

    @objc class func diffNewlyRemoved(latestPrefs: [URL], previous: [URL]) -> [URL] {
        previous.filter { !latestPrefs.contains($0) }
    }
}
