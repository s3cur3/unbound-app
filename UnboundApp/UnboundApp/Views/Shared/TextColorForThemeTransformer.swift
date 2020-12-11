//
// Created by Ryan Harter on 6/5/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa

/**
 * ValueTransformer to return a text color based on the theme.
 */
@objc class TextColorForThemeTransformer: ValueTransformer {
    // just to make things easier from objc
    @objc class func newInstance() -> TextColorForThemeTransformer {
        TextColorForThemeTransformer()
    }

    private let darkThemeTextColor = NSColor(calibratedWhite: 0.55, alpha: 1.0)
    private let lightThemeTextColor = NSColor.textColor

    override class func transformedValueClass() -> AnyClass {
        NSNumber.self
    }

    override class func allowsReverseTransformation() -> Bool {
        false
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let type = value as? NSNumber else { return nil }
        if type == 0 { // light
            return lightThemeTextColor
        } else {
            return darkThemeTextColor
        }
    }
}
