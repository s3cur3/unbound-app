//
// Created by Ryan Harter on 5/19/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa

class RegularPhotoItem : NSCollectionViewItem, PhotoItem {

  let normalBgColor = NSColor(calibratedWhite: 0.5, alpha: 0.2).cgColor
  let selectedBgColor = NSColor(calibratedWhite: 0.5, alpha: 0.4).cgColor

  private static let dateFormatter: DateFormatter = {
    let format = DateFormatter()
    format.dateFormat = "MM/dd/yy h:mm a"
    return format
  }()

  private lazy var selectionLayer: CALayer = {
    let layer = CALayer()
    layer.borderWidth = 4.0
    layer.cornerRadius = 2.0
    layer.borderColor = CGColor(red: 0.189, green: 0.657, blue: 0.859, alpha: 1)
    self.selectionView?.layer = layer
    layer.isHidden = true
    return layer
  }()


  override var isSelected: Bool {
    didSet {
      selectionLayer.isHidden = !isSelected
      self.view.layer?.backgroundColor = isSelected ? selectedBgColor : normalBgColor
    }
  }

  private let placeholder = NSImage(named: NSImage.Name(rawValue: "temp"))

  @IBOutlet weak var selectionView: NSView!
  @IBOutlet weak var playButton: NSImageView!
  @IBOutlet weak var dateView: NSTextField!
  @IBOutlet weak var titleView: NSTextField!

  @objc var photo: PIXPhoto? {
    didSet {
      self.representedObject = photo
      guard self.isViewLoaded else { return }

      if oldValue != nil {
        NotificationCenter.default.removeObserver(self, name: .photoThumbDidChange, object: oldValue)
      }
      guard let photo = photo else {
        self.prepareForReuse()
        return
      }

      self.playButton.isHidden = !photo.isVideo()
      self.titleView.stringValue = photo.name

      // Date taken is optional (derived from metadata), so we must handle accordingly.
      if let date = photo.dateTaken {
        self.dateView.isHidden = false
        self.dateView.stringValue = RegularPhotoItem.dateFormatter.string(from: date)
      } else if let date = photo.dateCreated {
        self.dateView.isHidden = false
        self.dateView.stringValue = RegularPhotoItem.dateFormatter.string(from: date)
      } else {
        self.dateView.isHidden = true
      }

      setImage(image: self.photo?.thumbnailImage)

      NotificationCenter.default.addObserver(forName: .photoThumbDidChange,
              object: photo, queue: OperationQueue.main) { notification in
        self.setImage(image: self.photo?.thumbnailImage)
      }
    }
  }

  private func setImage(image: NSImage?) {
    self.imageView?.image = image ?? placeholder

    // Fit the selection layer around the image
    guard let image = image,
          let imageView = self.imageView
            else { return }

    let imageFrame = NSMakeRect(0.0, 0.0, image.size.width, image.size.height)
    self.selectionLayer.frame = imageFrame.fitting(container: imageView.frame).insetBy(dx: -5.0, dy: -5.0)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.wantsLayer = true
    self.view.layer?.backgroundColor = normalBgColor
  }

  override func prepareForReuse() {
    isSelected = false
    playButton.isHidden = true
    titleView.stringValue = ""
    dateView.stringValue = ""
    imageView?.image = nil
    self.photo?.cancelThumbnailLoadOperation = true
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
