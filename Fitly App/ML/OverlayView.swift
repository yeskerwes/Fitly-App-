//
//  OverlayViewSwift.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 08.12.2025.
//

import UIKit
import Vision

final class OverlayView: UIView {
    private var overlayImage: CGImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }

    func updateImage(_ image: CGImage?) {
        DispatchQueue.main.async {
            self.overlayImage = image
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        if let img = overlayImage {
            ctx.draw(img, in: rect)
        }
    }
}
