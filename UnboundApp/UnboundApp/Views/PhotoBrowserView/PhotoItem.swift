//
// Created by Ryan Harter on 5/25/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

@objc protocol PhotoItem {
    var photo: PIXPhoto? { get set }
    var view: NSView { get }
}
