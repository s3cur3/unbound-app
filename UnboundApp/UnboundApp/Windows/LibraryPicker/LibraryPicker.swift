
import SwiftUI

struct LibraryPicker: View {
    @State var directories: [LibraryDirectory] = ["/Users/tyler/Dropbox", "/Users/tyler/Desktop", "/Users/tyler/Pictures", "/Volumes/Synology", "/Volumes/Synology2", "~/Lorem/Ipsum/Dolar/sit-amet/consectetur-adipiscing-elit", "~/Documents"].map { LibraryDirectory(withUrl: URL(string: $0)!) }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Library Directories to Scan for Photos")
                .font(.headline)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))

            List {
                ForEach(directories) { dir in
                    HStack(alignment: .center) {
                        Button(action: {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir.path.absoluteString)
                        }, label: {
                            Text(dir.path.absoluteString)
                                .frame(width: 280, alignment: .leading)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }).buttonStyle(LinkButtonStyle())

                        // TODO: Count of images we've found here?
                        Spacer()

                        Button("Remove") {
                            print("TODO: nuke")
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                }.moveDisabled(true)
            }
        }
    }
}

struct LibraryPickerPreview: PreviewProvider {
    static var previews: some View {
        LibraryPicker()
            .frame(width: 400.0, height: 240)
    }
}
