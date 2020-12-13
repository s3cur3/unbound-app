
import SwiftUI

struct LibraryPicker: View {
    let urls: [LibraryDirectory] = [LibraryDirectory(withUrl: URL(string: "~/Dropbox")!)]

    var body: some View {
        List(urls) { url in
            Text(url.path.absoluteString)
            Text("Ahoy")
        }
        .frame(minWidth: 300, minHeight: 300)
    }
}
