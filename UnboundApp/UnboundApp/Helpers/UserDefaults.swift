//
// Created by Ryan Harter on 6/12/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

extension UserDefaults {
  subscript(key: String) -> Any? {
    get {
      return self.object(forKey: key)
    }
    set(newValue) {
      self.set(newValue, forKey: key)
    }
  }
}
