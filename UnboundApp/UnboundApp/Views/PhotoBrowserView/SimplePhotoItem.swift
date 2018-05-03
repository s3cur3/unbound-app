//
// Created by Ryan Harter on 5/1/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa

let PhotoThumbDidChangeNotification = Notification.Name.init(rawValue: "PhotoThumbDidChangeNotification")

@objc class SimplePhotoItem: NSCollectionViewItem {

  override var isSelected: Bool {
    get {
      return super.isSelected
    }
    set {
      super.isSelected = newValue
      if newValue {
        self.imageView?.layer?.borderWidth = 4.0
        self.imageView?.layer?.cornerRadius = 2.0
        self.imageView?.layer?.borderColor = CGColor(red: 0.189, green: 0.657, blue: 0.859, alpha: 1)
      } else {
        self.imageView?.layer?.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
      }
      self.imageView?.needsDisplay = true
    }
  }

  private let placeholder = NSImage(named: NSImage.Name(rawValue: "temp"))

  @IBOutlet weak var playButton: NSImageView!
  
  @objc var photo: PIXPhoto? {
    didSet {
      if oldValue != nil {
        NotificationCenter.default.removeObserver(self, name: PhotoThumbDidChangeNotification, object: oldValue)
      }
      guard photo != nil else {
        self.prepareForReuse()
        return
      }

      NotificationCenter.default.addObserver(forName: PhotoThumbDidChangeNotification,
              object: photo!,
              queue: OperationQueue.main) { notification in
        self.updateView(forPhoto: self.photo!)
      }

      self.updateView(forPhoto: self.photo!)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.wantsLayer = true
  }

  override func prepareForReuse() {
    self.playButton.isHidden = true
    self.imageView!.image = placeholder
    self.imageView?.layer?.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
  }

  private func updateView(forPhoto photo: PIXPhoto) {
//    self.imageLoader.load(photo.path)
//        .placeholder("temp")
//        .into(self.imageView)

    let image = photo.thumbnailImage ?? placeholder
    self.imageView?.image = image

    if photo.isVideo() {
      self.playButton.isHidden = !photo.isVideo()
    }
    self.view.needsDisplay = true
  }

}
