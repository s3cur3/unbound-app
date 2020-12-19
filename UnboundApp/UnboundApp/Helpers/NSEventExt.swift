//
// Created by Ryan Harter on 3/13/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

extension NSEvent {
    func isCommandW() -> Bool {
        modifierFlags.contains(.command) && characters == "w"
    }
}
