//
//  ImageViewCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 12.12.2025.
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private init() {}

    private let cache = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: "image.loader.disk")

    func load(_ url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url.absoluteString as NSString) {
            return cached
        }

        if let diskImage = loadFromDisk(url: url) {
            cache.setObject(diskImage, forKey: url.absoluteString as NSString)
            return diskImage
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let img = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        cache.setObject(img, forKey: url.absoluteString as NSString)
        saveToDisk(imageData: data, url: url)
        return img
    }

    private func cachePath(for url: URL) -> URL {
        let fileName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        let fm = FileManager.default
        let caches = try? fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return caches?.appendingPathComponent("fitly_images_\(fileName)") ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }

    private func saveToDisk(imageData: Data, url: URL) {
        let path = cachePath(for: url)
        ioQueue.async {
            try? imageData.write(to: path, options: .atomic)
        }
    }

    private func loadFromDisk(url: URL) -> UIImage? {
        let path = cachePath(for: url)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        guard let data = try? Data(contentsOf: path), let img = UIImage(data: data) else { return nil }
        return img
    }
}

