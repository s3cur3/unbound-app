
import SwiftUI

struct LibraryPicker: View {
    let directories: [LibraryDirectory]

    init(dirs: [LibraryDirectory]) {
        directories = dirs
    }

    var body: some View {
        HStack {
			ScrollView(.vertical, showsIndicators: true) {
				VStack {
					ForEach(directories) { dir in
						HStack(alignment: .top) {
							Button(dir.path.absoluteString) {
								print("TODO: Open in Finder")
							}
							.frame(alignment: .leading)
							.buttonStyle(LinkButtonStyle())

							// TODO: Count of images we've found here?
							Spacer()
							
							Button("Remove") {
								print("TODO: nuke")
							}
							.buttonStyle(BorderedButtonStyle())
						}
					}
				}
				.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }.frame(maxWidth: .infinity, maxHeight: .infinity)

            Text("Hi")
        }.frame(width: 400, height: 280, alignment: .leading)
    }
}

struct LibraryPickerPreview: PreviewProvider {
    static var previews: some View {
        LibraryPicker(dirs: [LibraryDirectory(withUrl: URL(string: "~/Dropbox")!), LibraryDirectory(withUrl: URL(string: "~/Documents")!), LibraryDirectory(withUrl: URL(string: "~/Pictures")!)])
            .frame(width: 400.0, height: 280)
    }
}
