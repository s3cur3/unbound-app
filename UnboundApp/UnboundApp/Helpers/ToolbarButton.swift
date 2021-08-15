//
// Created by Ryan Harter on 10/18/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

import Cocoa

@objc class ToolbarButton: NSButton {

  @objc init(imageNamed imageName: String, target: AnyObject?, action: Selector?) {
    super.init(frame: NSMakeRect(0, 0, 46, 29))

    let image = NSImage(named: NSImage.Name(imageName))!
    image.isTemplate = true
    self.image = image
    self.imagePosition = .imageOverlaps
    self.imageScaling = .scaleProportionallyDown
    self.isBordered = true
    self.bezelStyle = .texturedSquare
    self.title = ""
    self.target = target
    self.action = action
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

}
