//
// Created by Ryan Harter on 10/18/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

import Cocoa

@objc class ToolbarButton: NSButton {
    @objc init(imageNamed imageName: String, target: AnyObject?, action: Selector?) {
        super.init(frame: NSMakeRect(0, 0, 46, 29))

        let image = NSImage(named: imageName)!
        image.isTemplate = true
        self.image = image
        imagePosition = .imageOverlaps
        imageScaling = .scaleProportionallyDown
        isBordered = true
        bezelStyle = .texturedSquare
        title = ""
        self.target = target
        self.action = action
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
