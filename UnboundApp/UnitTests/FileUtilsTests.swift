import XCTest

class FileUtilsTests: XCTestCase {
    func testPathHasAncestor() throws {
        let leaf = URL(fileURLWithPath: "/foo/bar/baz")
        let parent = leaf.deletingLastPathComponent()
        XCTAssertTrue(pathHasAncestor(maybeChild: leaf, maybeAncestor: parent))
        XCTAssertFalse(pathHasAncestor(maybeChild: URL(fileURLWithPath: "/foo/bar 1/baz"), maybeAncestor: parent))
        XCTAssertFalse(pathHasAncestor(maybeChild: leaf, maybeAncestor: leaf))
    }

    func testPathFormatting() throws {
        let home = URL(fileURLWithPath: "/Users/jdoe")
        XCTAssertEqual(formatForDisplay(home), "/Users/jdoe")

        let dropbox = URL(fileURLWithPath: "/Users/tyler/Dropbox")
        XCTAssertEqual(formatForDisplay(dropbox), "~/Dropbox")

        let cameraUploads = URL(fileURLWithPath: "/Users/tyler/Dropbox/Camera Uploads")
        XCTAssertEqual(formatForDisplay(cameraUploads), "~/Dropbox/Camera Uploads")

        let externalVol = URL(fileURLWithPath: "/Volumes/External Drive")
        XCTAssertEqual(formatForDisplay(externalVol), "External Drive")

        let externalVolSubDirectory = URL(fileURLWithPath: "/Volumes/External Drive/Photos")
        XCTAssertEqual(formatForDisplay(externalVolSubDirectory), "Photos")
    }
}
