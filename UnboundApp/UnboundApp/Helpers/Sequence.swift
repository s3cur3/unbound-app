//
// Created by Ryan Harter on 6/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

extension Sequence {

  public func forEachIndexed(_ body: (Self.Element, Int) throws -> Swift.Void) rethrows {
    var index = 0
    try self.forEach { (e: Element) in
      try body(e, index)
      index += 1
    }
  }
}
