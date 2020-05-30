//
// Created by Ryan Harter on 5/3/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

class SimplePhotoItemView: NSView {

  var isVideo = false {
    didSet { updateLayer() }
  }
  var image: NSImage? {
    didSet { updateLayer() }
  }
  var selected = false {
    didSet { updateLayer() }
  }

  override var wantsUpdateLayer: Bool { return true }
  override var isOpaque: Bool { return false }
  override var frame: NSRect { didSet { updateLayer() } }

  private var playButton: NSImageView?

  private lazy var imageLayer: CALayer = { CALayer() }()
  private lazy var selectionLayer: CALayer = {
    let layer = CALayer()
    layer.borderWidth = 4.0
    layer.cornerRadius = 2.0
    layer.borderColor = CGColor(red: 0.189, green: 0.657, blue: 0.859, alpha: 1)
    return layer
  }()

  override init(frame: NSRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    setup()
  }

  private func setup() {
    self.layer = CALayer()
    guard let layer = self.layer else {
      return
    }

    self.imageLayer.delegate = self
    self.selectionLayer.delegate = self
    layer.delegate = self

    layer.sublayers = [self.imageLayer, self.selectionLayer]
    self.wantsLayer = true
  }

  private func createPlayButton() -> NSImageView {
    if let playButton = self.playButton {
      return playButton
    }

    let imageView = NSImageView()
    imageView.image = NSImage(named: "playbutton")
    imageView.imageScaling = .scaleProportionallyDown
    imageView.autoresizesSubviews = true
    imageView.wantsLayer = true
    imageView.layer?.delegate = self
    self.playButton = imageView
    return imageView
  }

  override func updateLayer() {
    guard let image = self.image else { return }
    let rect = self.bounds.insetBy(dx: 5.0, dy: 5.0)
    let imageSize = image.size
    var imageFrame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
    if imageSize.width > 0 && imageSize.height > 0 {
      if imageSize.width / imageSize.height > rect.size.width / rect.size.height {
        let scale = rect.size.width / imageSize.width
        imageFrame.size.width = rint(scale * imageFrame.size.width)
        imageFrame.size.height = rint(scale * imageFrame.size.height)

        imageFrame.origin.x = rint(rect.origin.x)
        imageFrame.origin.y = rint((rect.size.height - imageFrame.size.height) / 2 + rect.origin.y)
      } else {
        let scale = rect.size.height / imageSize.height
        imageFrame.size.width = rint(scale * imageFrame.size.width)
        imageFrame.size.height = rint(scale * imageFrame.size.height)

        imageFrame.origin.y = rint(rect.origin.y)
        imageFrame.origin.x = rint((rect.size.width - imageFrame.size.width) / 2 + rect.origin.x)
      }
    }
    self.imageLayer.frame = imageFrame

    if selected {
      self.selectionLayer.frame = imageFrame.insetBy(dx: -5.0, dy: -5.0)
      self.layer!.addSublayer(self.selectionLayer)
    } else {
      self.selectionLayer.removeFromSuperlayer()
    }

    if (isVideo) {
      var videoThumbFrame = CGRect(x: 0, y: 0, width: 80, height: 80)
      if imageFrame.size.width > 0 && imageFrame.size.height > 0 {
        if imageSize.width / imageSize.height > rect.size.width / rect.size.height {
          let scale = rect.size.width / 200.0
          videoThumbFrame.size.width = rint(scale * videoThumbFrame.size.width)
          videoThumbFrame.size.height = rint(scale * videoThumbFrame.size.height)

          videoThumbFrame.origin.y = rint((rect.size.height - videoThumbFrame.size.height) / 2 + rect.origin.y)
          videoThumbFrame.origin.x = rint((rect.size.width - videoThumbFrame.size.width) / 2 + rect.origin.x)
        } else {
          let scale = rect.size.height / 200.0;
          videoThumbFrame.size.width = rint(scale * videoThumbFrame.size.width);
          videoThumbFrame.size.height = rint(scale * videoThumbFrame.size.height);

          videoThumbFrame.origin.y = rint((rect.size.height - videoThumbFrame.size.height) / 2 + rect.origin.y);
          videoThumbFrame.origin.x = rint((rect.size.width - videoThumbFrame.size.width) / 2 + rect.origin.x);
        }
      }
      self.playButton?.frame = videoThumbFrame
      self.layer!.addSublayer(self.createPlayButton().layer!)
    } else {
      self.playButton?.layer?.removeFromSuperlayer()
      self.playButton = nil
    }

    self.imageLayer.contents = self.image
  }
}

extension SimplePhotoItemView: CALayerDelegate {
  func action(for layer: CALayer, forKey event: String) -> CAAction? {
    return NSNull()
  }
}
