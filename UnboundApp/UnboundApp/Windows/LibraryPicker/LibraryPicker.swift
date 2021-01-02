
import SwiftUI

struct LibraryPicker: View {
    @ObservedObject var library: LibraryDirectories

    var body: some View {
        VStack(alignment: .leading) {
            Text("Library Directories to Scan for Photos")
                .font(.headline)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))

            List {
                ForEach(library.directories) { dir in
                    HStack(alignment: .center) {
                        Button(action: {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir.path.path)
                        }, label: {
                            Text(LibraryPicker.formatPath(dir))
                                .frame(width: 280, alignment: .leading)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }).buttonStyle(LinkButtonStyle())

                        // TODO: Count of images we've found here?
                        Spacer()

                        Button("Remove") {
                            library.remove(dir)
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                }.moveDisabled(true)
            }

            HStack {
                Spacer()

                Button("Add Directory to Scan") {
                    library.add(LibraryDirectory.chooseFromSystemDialog())
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
            }
        }
    }

    static func formatPath(_ dir: LibraryDirectory) -> String {
        dir.path.path
    }
}

struct LibraryPickerPreview: PreviewProvider {
    static var previews: some View {
        let previewDirs = ["/Users/tyler/Dropbox", "/Users/tyler/Desktop", "/Users/tyler/Pictures", "/Volumes/Synology", "/Volumes/Synology2", "~/Lorem/Ipsum/Dolar/sit-amet/consectetur-adipiscing-elit", "~/Documents"]
            .map { LibraryDirectory(withUrl: URL(string: $0)!) }
        LibraryPicker(library: LibraryDirectories(withDirectories: previewDirs))
            .frame(width: 400.0, height: 240)
    }
}
