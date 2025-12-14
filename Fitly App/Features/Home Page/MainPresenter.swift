//
//  MainPresenter.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 14.12.2025.
//

import UIKit

final class MainPresenter {

    private let service: ChallengeServiceProtocol

    init(service: ChallengeServiceProtocol = ChallengeService.shared) {
        self.service = service
    }

    func loadChallenges() -> [ChallengeEntity] {
        service.fetchActive()
    }

    func cancelChallenge(_ challenge: ChallengeEntity) {
        service.cancel(challenge)
    }

    func profileInfo() -> (name: String, avatar: UIImage?) {
        (service.currentUsername(), service.currentAvatar())
    }
}
