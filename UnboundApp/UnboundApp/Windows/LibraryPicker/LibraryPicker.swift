
import SwiftUI

struct LibraryPicker: View {
    @ObservedObject var library: LibraryDirectories
    var supportsRescan: Bool = true
    var topPadding: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(library.directories) { dir in
                    HStack(alignment: .center) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            PathControl(url: dir.path)
                        }

                        // TODO: Count of images we've found here?
                        Spacer()

                        Button("Remove") {
                            library.remove(dir)
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                }.moveDisabled(true)
            }

            HStack {
                Button("Add Directory to Scan") {
                    library.add(LibraryDirectory.chooseFromSystemDialog(withExisting: LibraryDirectories.fromPrefs()))
                }

                if supportsRescan && !library.directories.isEmpty {
                    Spacer()

                    Button("Rescan All") {
                        PIXFileParser.shared().rescanFiles()
                    }
                }
            }.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
        }.padding(EdgeInsets(top: topPadding, leading: 0, bottom: 0, trailing: 0))
    }

    static func formatPath(_ dir: LibraryDirectory) -> String {
        dir.path.path
    }
}

struct LibraryPickerForPrefs: View {
    @ObservedObject var library: LibraryDirectories

    var body: some View {
        VStack(alignment: .leading) {
            Text("Photo Folder(s)").font(.headline)

            Text("Unbound will scan these folders and all their sub-folders.")
                .padding(EdgeInsets(top: 2, leading: 0, bottom: 4, trailing: 0))

            LibraryPicker(library: library, supportsRescan: true)
        }
    }
}

struct LibraryPickerWindow: View {
    @ObservedObject var library: LibraryDirectories

    var body: some View {
        VStack(alignment: .leading) {
            Text("Unbound will scan these folders and all their sub-folders.")
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))

            LibraryPicker(library: library)
        }.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
}

struct LibraryPickerWindowPreview: PreviewProvider {
    static var previews: some View {
        let previewDirs = ["/Users/tyler/Dropbox", "~/Lorem/Ipsum/Dolar/sit-amet/consectetur-adipiscing-elit", "/Users/tyler/Desktop", "/Users/tyler/Pictures", "/Volumes/Synology", "/Volumes/Synology2", "~/Documents"]
            .map { LibraryDirectory(withUrl: URL(string: $0)!) }
        LibraryPickerWindow(library: LibraryDirectories(withDirectories: previewDirs))
            .frame(width: 400.0, height: 240)
    }
}
