//
//  ChallengeServices.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 14.12.2025.
//

import UIKit

protocol ChallengeServiceProtocol {
    func fetchActive() -> [ChallengeEntity]
    func cancel(_ challenge: ChallengeEntity)
    func currentUsername() -> String
    func currentAvatar() -> UIImage?
}

final class ChallengeService: ChallengeServiceProtocol {

    static let shared = ChallengeService()
    private init() {}

    func fetchActive() -> [ChallengeEntity] {
        CoreDataManager.shared.fetchChallenges(status: "active")
    }

    func cancel(_ challenge: ChallengeEntity) {
        CoreDataManager.shared.updateStatus(for: challenge, to: "cancelled")
    }

    func currentUsername() -> String {
        CoreDataManager.shared.currentUsername()
    }

    func currentAvatar() -> UIImage? {
        CoreDataManager.shared.currentAvatarImage()
    }
}
