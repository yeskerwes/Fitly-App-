//
//  ProfileService.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 14.12.2025.
//

import UIKit

final class ProfileService {

    static let shared = ProfileService()
    private init() {}

    func currentUsername() -> String {
        CoreDataManager.shared.currentUsername()
    }

    func saveUsername(_ name: String) {
        CoreDataManager.shared.saveUsername(name)
    }

    func currentAvatarImage() -> UIImage? {
        CoreDataManager.shared.currentAvatarImage()
    }

    func saveAvatarImage(_ image: UIImage?) {
        CoreDataManager.shared.saveAvatarImage(image)
    }

    func resizedImage(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: image.size.width * scale,
                             height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result ?? image
    }
}
