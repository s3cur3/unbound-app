//
// Created by Ryan Harter on 5/19/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Cocoa

class RegularPhotoItem : NSCollectionViewItem {

  let PhotoThumbDidChangeNotification = Notification.Name.init(rawValue: "PhotoThumbDidChangeNotification")


  override var isSelected: Bool {
    didSet { self.itemView.selected = isSelected }
  }

  private let placeholder = NSImage(named: NSImage.Name(rawValue: "temp"))

  @IBOutlet weak var itemView: SimplePhotoItemView!
  @IBOutlet weak var titleView: NSTextField!

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
        self.itemView.isVideo = self.photo?.isVideo() ?? false
        self.itemView.image = self.photo?.thumbnailImage
        if let title = self.photo?.title {
          self.titleView.stringValue = title
        }
      }

      self.itemView.isVideo = self.photo?.isVideo() ?? false
      self.itemView.image = self.photo!.thumbnailImage
      if let title = self.photo?.title {
        self.titleView.stringValue = title
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.wantsLayer = true
  }

  override func prepareForReuse() {
    self.itemView.isVideo = false
    self.itemView.image = nil
    self.itemView.selected = false
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
