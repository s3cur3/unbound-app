import XCTest

class FileUtilsTests: XCTestCase {
    func testPathHasAncestor() throws {
        let leaf = URL(fileURLWithPath: "/foo/bar/baz")
        let parent = leaf.deletingLastPathComponent()
        XCTAssertTrue(pathHasAncestor(maybeChild: leaf, maybeAncestor: parent))
        XCTAssertFalse(pathHasAncestor(maybeChild: URL(fileURLWithPath: "/foo/bar 1/baz"), maybeAncestor: parent))
        XCTAssertFalse(pathHasAncestor(maybeChild: leaf, maybeAncestor: leaf))
    }
}
