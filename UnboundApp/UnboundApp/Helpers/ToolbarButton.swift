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
        imageScaling = .scaleNone
        setButtonType(.momentaryPushIn)
        showsBorderOnlyWhileMouseInside = false
        isBordered = true
        bezelStyle = .texturedRounded
        title = ""
        self.target = target
        self.action = action
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc class func makePhotoSort(target: AnyObject, selector: Selector) -> NSToolbarItem {
        makeSort(target: target, selector: selector, label: "Sort Photos", tooltip: "Choose photo sort order", prefsKey: prefPhotoSortOrder)
    }

    @objc class func makeAlbumSort(target: AnyObject, selector: Selector) -> NSToolbarItem {
        makeSort(target: target, selector: selector, label: "Sort Albums", tooltip: "Choose album sort order", prefsKey: prefAlbumSortOrder)
    }

    class func makeSort(target: AnyObject, selector: Selector, label: String, tooltip: String, prefsKey: String) -> NSToolbarItem {
        let buttonView = NSPopUpButton(frame: CGRect(x: 0, y: 0, width: 46, height: 29), pullsDown: true)
        buttonView.imagePosition = .imageOverlaps
        buttonView.isBordered = true
        buttonView.bezelStyle = .texturedRounded
        buttonView.title = ""
        (buttonView.cell as? NSPopUpButtonCell)?.arrowPosition = .noArrow

        buttonView.insertItem(withTitle: "", at: 0) // first index is always the title
        buttonView.insertItem(withTitle: "New to Old", at: 1)
        buttonView.insertItem(withTitle: "Old to New", at: 2)
        buttonView.insertItem(withTitle: "A to Z", at: 3)
        buttonView.insertItem(withTitle: "Z to A", at: 4)

        buttonView.itemArray[0].image = NSImage(named: "ic_sort")
        buttonView.itemArray[0].image?.isTemplate = true

        let sortOrder = UserDefaults.standard.integer(forKey: prefsKey)

        for i in 1 ... 4 {
            let item = buttonView.itemArray[i]
            item.state = i - 1 == sortOrder ? .on : .off
            item.tag = i - 1
            item.target = target
            item.action = selector
        }

        let sortButton = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("sortButton"))
        sortButton.label = label
        sortButton.paletteLabel = label
        sortButton.toolTip = tooltip
        sortButton.view = buttonView
        return sortButton
    }
}
