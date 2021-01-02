// An inline view of a path, like:
// Macintosh HD > Users > tyler > Dropbox > Photos
// With acknowledgments to PopUpPathControl by Łukasz Rutkowski: https://github.com/Tunous/PathControl

import SwiftUI

/// A control for display of a file system path or virtual path information.
public struct PathControl: NSViewRepresentable {
    @ObservedObject private var delegate = PathControlDelegate()
    @State private var url: URL?

    public init(url: URL) {
        _url = State(initialValue: url)
    }

    public func makeNSView(context _: Context) -> NSPathControl {
        let pathControl = NSPathControl()
        pathControl.pathStyle = .standard
        pathControl.url = url

        pathControl.target = delegate
        pathControl.action = #selector(delegate.pathItemClicked)
        pathControl.delegate = delegate

        return pathControl
    }

    public func updateNSView(_ nsView: NSPathControl, context _: Context) {
        nsView.url = url
    }
}
