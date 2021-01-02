import Foundation
import SwiftUI

final class PathControlDelegate: NSObject, ObservableObject, NSPathControlDelegate {
    var urlChanged: (URL?) -> Void = { _ in }

    @objc func pathItemClicked(_ sender: NSPathControl) {
        if let url = sender.clickedPathItem?.url {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        }
    }
}
