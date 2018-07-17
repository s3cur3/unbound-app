//
// Created by Ryan Harter on 6/26/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//
import Foundation

extension NSRect {
  func fitting(container: NSRect) -> NSRect {
    let containerWidth = container.width
    let containerHeight = container.height
    let width = size.width
    let height = size.height

    let scale = min(containerWidth / width, containerHeight / height)
    let dx = round((containerWidth - width * scale) * 0.5) + container.origin.x
    let dy = round((containerHeight - height * scale) * 0.5) + container.origin.y
    return NSMakeRect(dx, dy, width * scale, height * scale)
  }
}