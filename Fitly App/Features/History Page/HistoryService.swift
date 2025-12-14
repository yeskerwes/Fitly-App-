//
//  HistoryService.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 15.12.2025.
//

import Foundation
import CoreData

final class HistoryService {

    static let shared = HistoryService()
    private init() {}

    func loadHistory() -> [ChallengeEntity] {
        let completed = CoreDataManager.shared.fetchChallenges(status: "completed")
        let cancelled = CoreDataManager.shared.fetchChallenges(status: "cancelled")

        return (completed + cancelled).sorted { a, b in
            let dateA = preferredHistoryDate(for: a) ?? .distantPast
            let dateB = preferredHistoryDate(for: b) ?? .distantPast
            return dateA > dateB
        }
    }

    func delete(_ entity: ChallengeEntity) {
        CoreDataManager.shared.delete(entity)
    }

    private func preferredHistoryDate(for entity: ChallengeEntity) -> Date? {
        if entity.entity.attributesByName.keys.contains("completedAt"),
           let d = entity.value(forKey: "completedAt") as? Date {
            return d
        }
        return entity.createdAt
    }
}
