//
// Created by Ryan Harter on 10/17/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

import Cocoa

@objc class NavigationController: NSViewController {
    @IBOutlet var mainWindow: NSWindow!
    @IBOutlet var toolbar: NSToolbar!

    @objc var showBackButton: Bool = true {
        didSet {
            if showBackButton != oldValue {
                updateToolbar()
            }
        }
    }

    fileprivate var viewControllers = [PIXViewController]()
    private var titleObservation: NSKeyValueObservation?

    private var toolbarItems: [NSToolbarItem]?
    private var leftItems: [NSToolbarItem]?
    private var rightItems: [NSToolbarItem]?

    private var titleView: NSTextField!
    private let titleItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("Title"))
    private let adaptiveSpace = AdaptiveToolbarSpaceItem(itemIdentifier: NSToolbarItem.Identifier("AdaptiveSpace"))
    private let backButton = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("BackButton"))
    private let activityIndicator = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("ActivityIndicator"))

    override public init(nibName _: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mainWindow.titleVisibility = .hidden

        if #available(OSX 10.12, *) {
            titleView = NSTextField(string: "Unbound")
        } else {
            titleView = NSTextField(frame: NSMakeRect(0, 0, 120, 25))
            titleView.stringValue = "Unbound"
        }
        titleView.alignment = .center
        titleView.isEditable = false
        titleView.isBordered = false
        titleView.backgroundColor = NSColor(white: 0, alpha: 0)
        titleItem.view = titleView
        titleItem.visibilityPriority = NSToolbarItem.VisibilityPriority.high

        var button: NSButton
        if #available(OSX 10.12, *) {
            button = NSButton(title: "Back", image: NSImage(named: NSImage.goLeftTemplateName)!, target: self, action: #selector(NavigationController.popViewController))
            button.frame = NSMakeRect(0, 0, 79, 29)
        } else {
            button = NSButton(frame: NSMakeRect(0, 0, 79, 29))
            button.title = "Back"
            button.image = NSImage(named: NSImage.goLeftTemplateName)!
            button.target = self
            button.action = #selector(popViewController)
        }
        button.imageScaling = .scaleProportionallyDown
        button.alignment = .center
        button.imagePosition = .imageLeft
        button.bezelStyle = .texturedRounded
        button.isBordered = true
        if #available(OSX 10.12, *) {
            button.imageHugsTitle = true
        }

        backButton.view = button
        backButton.label = "Back"
        backButton.paletteLabel = "Back"
        backButton.toolTip = "Navigate Back"

        // Create activity indicator
        let spinner = PIXSeperatedSpinnerView(frame: NSMakeRect(0, 0, 18, 18))
        spinner.indicator.bind(NSBindingName("animate"), to: PIXFileParser.shared()!, withKeyPath: "isWorking")

        activityIndicator.view = spinner
        activityIndicator.label = "Activity"
        activityIndicator.paletteLabel = "Activity"
        activityIndicator.toolTip = "Activity"
    }

    // MARK: - ViewController Management

    @objc func pushViewController(viewController: PIXViewController) {
        mainWindow.disableFlushing()

        if let currentViewController = viewControllers.last {
            titleObservation = nil
            currentViewController.willHidePIXView()
            currentViewController.view.removeFromSuperview()
        }

        // reset the back button state
        showBackButton = true

        titleObservation = viewController.observe(\.title) { object, _ in
            self.setTitle(title: object.title)
        }
        viewController.navigationViewController = self
        viewController.view.frame = view.bounds
        viewController.willShowPIXView()
        setTitle(title: viewController.title)
        view.addSubview(viewController.view)
        viewController.view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]

        viewControllers.append(viewController)

        mainWindow.enableFlushing()

        updateToolbar()
    }

    @objc func popViewController() {
        if viewControllers.count <= 1 {
            return
        }

        mainWindow.disableFlushing()

        let oldViewController = viewControllers.removeLast()
        oldViewController.willHidePIXView()
        oldViewController.view.removeFromSuperview()
        oldViewController.navigationViewController = nil
        titleObservation = nil

        // reset the back button state
        showBackButton = true

        if let newViewController = viewControllers.last {
            titleObservation = newViewController.observe(\.title) { object, _ in
                self.setTitle(title: object.title)
            }
            newViewController.view.frame = view.bounds
            newViewController.willShowPIXView()
            setTitle(title: newViewController.title)
            view.addSubview(newViewController.view)
        }

        mainWindow.enableFlushing()

        updateToolbar()
    }

    @objc func popToRootViewController() {
        if viewControllers.count <= 1 {
            return
        }

        let oldViewController = viewControllers.removeLast()
        oldViewController.willHidePIXView()
        oldViewController.view.removeFromSuperview()
        oldViewController.navigationViewController = nil
        titleObservation = nil

        while viewControllers.count > 1 {
            let controller = viewControllers.removeLast()
            controller.navigationViewController = nil
        }

        // reset the back button state
        showBackButton = true

        if let newViewController = viewControllers.last {
            titleObservation = newViewController.observe(\.title) { object, _ in
                self.setTitle(title: object.title)
            }
            newViewController.view.frame = view.bounds
            newViewController.willShowPIXView()
            view.addSubview(newViewController.view)
        }

        updateToolbar()
    }

    // MARK: - Key Handling

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // escape
            popViewController()
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Appearance

    @objc func setToolbarHidden(_ hidden: Bool) {
        if hidden, toolbar.isVisible {
            view.window?.toggleToolbarShown(self)
        } else if !toolbar.isVisible {
            view.window?.toggleToolbarShown(self)
        }
    }

    func setTitle(title: String?) {
        if let title = title {
            titleView.stringValue = title
        } else {
            titleView.stringValue = "Unbound"
        }

        // re-apply the string value, needed for the text field to correctly calculate it's width
        titleView.stringValue = titleView.stringValue

        // calculate new dimensions
        let maxWidth: CGFloat = 500
        let maxHeight: CGFloat = titleView.frame.size.height
        let size = titleView.sizeThatFits(NSSize(width: maxWidth, height: maxHeight))

        var frame = titleView.frame
        frame.size.width = size.width
        titleView.frame = frame

        var titleMinSize = titleItem.minSize
        titleMinSize.width = size.width
        titleItem.minSize = titleMinSize
        adaptiveSpace.updateWidth()

        view.window?.viewsNeedDisplay = true
    }

    // MARK: - Toolbar Methods

    @objc var leftToolbarItems: [NSToolbarItem]? {
        get {
            leftItems
        }
        set {
            leftItems = newValue
            updateToolbar()
        }
    }

    @objc var rightToolbarItems: [NSToolbarItem]? {
        get {
            rightItems
        }
        set {
            rightItems = newValue
            updateToolbar()
        }
    }
}

// Toolbar
extension NavigationController {
    func updateToolbar() {
        while toolbar.items.count > 0 {
            toolbar.removeItem(at: 0)
        }

        var items = [NSToolbarItem]()
        if showBackButton, viewControllers.count > 1 {
            items.append(backButton)
        }
        if let leftItems = self.leftItems {
            items.append(contentsOf: leftItems)
        }
        items.append(activityIndicator)
        items.append(adaptiveSpace)

        items.append(titleItem)
        items.append(NSToolbarItem(itemIdentifier: .flexibleSpace))

        if let rightItems = self.rightItems {
            items.append(contentsOf: rightItems)
        }

        toolbarItems = items
        for i in 0 ..< items.count {
            toolbar.insertItem(withItemIdentifier: items[i].itemIdentifier, at: i)
        }
        view.window?.viewsNeedDisplay = true
    }
}

extension NavigationController: NSToolbarDelegate {
    func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
        toolbarItems?.first { item in item.itemIdentifier == itemIdentifier }
    }
}
