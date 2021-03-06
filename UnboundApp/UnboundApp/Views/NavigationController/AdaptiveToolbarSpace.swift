//
// Created by Ryan Harter on 10/17/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

import Cocoa

private class AdapterToolbarSpaceView: NSView {
    fileprivate var adaptiveSpaceItem: AdaptiveToolbarSpaceItem?

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        false
    }

    override func viewDidMoveToWindow() {
        NotificationCenter.default.addObserver(self, selector: #selector(AdapterToolbarSpaceView.windowResized), name: NSWindow.didResizeNotification, object: window)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func windowResized(note _: Notification) {
        adaptiveSpaceItem?.updateWidth()
    }
}

class AdaptiveToolbarSpaceItem: NSToolbarItem {
    override public init(itemIdentifier: NSToolbarItem.Identifier) {
        super.init(itemIdentifier: itemIdentifier)

        let itemView = AdapterToolbarSpaceView(frame: NSMakeRect(0, 0, 1, 1))
        itemView.adaptiveSpaceItem = self
        view = itemView
    }

    override var minSize: NSSize {
        get {
            let size = super.minSize

            guard let items = self.toolbar?.items else { return size }
            guard let index = items.firstIndex(of: self) else { return size }

            if index == NSNotFound {
                return size
            }

            guard let frame = self.view?.superview?.frame else { return size }

            if frame.origin.x <= 0 {
                return size
            }

            if items.count <= index + 1 {
                return size
            }

            let nextItem = items[index + 1]
            guard let nextFrame = nextItem.view?.superview?.frame else { return size }
            guard let toolbarFrame = nextItem.view?.superview?.superview?.frame else { return size }

            let space: CGFloat = (toolbarFrame.size.width - nextFrame.size.width) / 2 - frame.origin.x - 6

            if space > 0 {
                return NSMakeSize(space, size.height)
            } else {
                return size
            }
        }
        set {
            super.minSize = newValue
        }
    }

    override var maxSize: NSSize {
        get {
            let size = super.maxSize
            return NSMakeSize(minSize.width, size.height)
        }
        set {
            super.maxSize = newValue
        }
    }

    func updateWidth() {
        super.minSize = minSize
        super.maxSize = maxSize
    }
}
