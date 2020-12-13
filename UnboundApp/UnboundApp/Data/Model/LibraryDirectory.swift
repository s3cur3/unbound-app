struct LibraryDirectory: Codable, Equatable, Identifiable {
    var path: URL
    var id: String

    init(withUrl url: URL) {
        path = url
        id = url.absoluteString
    }
}
