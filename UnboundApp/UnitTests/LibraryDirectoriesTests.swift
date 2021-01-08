import XCTest

class LibraryDirectoriesTests: XCTestCase {
    func testDirectoriesUpdateOnPrefsChanges() throws {
        let lib = LibraryDirectories()
        let originalDirs = lib.directories

        let fakeDir1 = LibraryDirectory(withUrl: URL(fileURLWithPath: "/foo/bar/baz"))
        lib.add([fakeDir1])
        XCTAssertEqual(lib.directories, originalDirs + [fakeDir1])

        let fakeDir2 = LibraryDirectory(withUrl: URL(fileURLWithPath: "/whiz/bang/boop"))
        let fakeDir3 = LibraryDirectory(withUrl: URL(fileURLWithPath: "/whoop/bip"))
        lib.add([fakeDir2, fakeDir3])
        XCTAssertEqual(lib.directories, originalDirs + [fakeDir1, fakeDir2, fakeDir3])

        lib.remove(fakeDir2)
        XCTAssertEqual(lib.directories, originalDirs + [fakeDir1, fakeDir3])
        lib.remove(fakeDir1)
        XCTAssertEqual(lib.directories, originalDirs + [fakeDir3])
        lib.remove(fakeDir3)
        XCTAssertEqual(lib.directories, originalDirs)
    }
}
