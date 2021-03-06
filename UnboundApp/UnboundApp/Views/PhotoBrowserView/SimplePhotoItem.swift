//
// Created by Ryan Harter on 5/1/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa

@objc class SimplePhotoItem: NSCollectionViewItem, PhotoItem {
    private let placeholder = NSImage(named: "temp")

    private lazy var selectionLayer: CALayer = {
        let layer = CALayer()
        layer.borderWidth = 4.0
        layer.cornerRadius = 2.0
        layer.borderColor = CGColor(red: 0.189, green: 0.657, blue: 0.859, alpha: 0)
        self.selectionView?.layer = layer
        layer.isHidden = true
        return layer
    }()

    override var isSelected: Bool {
        didSet {
            selectionLayer.isHidden = !isSelected
            selectionLayer.borderColor = selectionLayer.borderColor?.copy(alpha: isSelected ? 1 : 0)
        }
    }

    @IBOutlet var selectionView: NSView!
    @IBOutlet var playButton: NSImageView!

    @objc var photo: PIXPhoto? {
        didSet {
            representedObject = photo
            guard isViewLoaded else { return }

            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: .photoThumbDidChange, object: oldValue)
            }
            guard let photo = photo else {
                prepareForReuse()
                return
            }

            playButton.isHidden = !photo.isVideo()
            setImage(image: photo.thumbnailImage)

            NotificationCenter.default.addObserver(forName: .photoThumbDidChange,
                                                   object: photo, queue: OperationQueue.main) { _ in
                self.setImage(image: self.photo?.thumbnailImage)
            }
        }
    }

    private func setImage(image: NSImage?) {
        self.imageView?.image = image ?? placeholder

        // Fit the selection layer around the image
        guard let image = image, let imageView = self.imageView else {
            return
        }

        let imageFrame = NSMakeRect(0.0, 0.0, image.size.width, image.size.height)
        selectionLayer.frame = imageFrame.fitting(container: imageView.frame).insetBy(dx: -5.0, dy: -5.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }

    override func prepareForReuse() {
        playButton.isHidden = true
        isSelected = false
        imageView?.image = placeholder
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount > 1 {
            NSApplication.shared.sendAction(#selector(PIXPhotoCollectionViewController.collectionItemViewDoubleClick),
                                            to: nil, from: self)
        }
    }

    override func keyDown(with event: NSEvent) {
        // check for enter or return (from Events.h)
        if event.keyCode == 3 || event.keyCode == 13 {
            NSApplication.shared.sendAction(#selector(PIXPhotoCollectionViewController.collectionItemViewDoubleClick),
                                            to: nil, from: self)
        }
        super.keyDown(with: event)
    }
}
