//
//  SearchViewModel.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 14.12.2025.
//

import Foundation

final class SearchViewModel {

    private let youtubeService: YouTubeServiceProtocol

    private(set) var results: [VideoItem] = []
    private(set) var suggestions: [String] = []

    private let staticSuggestions: [String] = [
        "Push up technique",
        "Proper squat form",
        "How to plank",
        "Push up common mistakes",
        "Squat depth explained",
        "Beginner push up progression",
        "How to do burpees",
        "Correct squat knee alignment",
        "Hip hinge vs squat",
        "Bodyweight workout for beginners"
    ]

    init(youtubeService: YouTubeServiceProtocol = YouTubeService.shared) {
        self.youtubeService = youtubeService
    }

    func search(query: String) async throws {
        results = try await youtubeService.search(query: query, maxResults: 12)
    }

    // MARK: - Suggestions
    func reloadSuggestions(filter: String, recentSearches: [String]) {
        if filter.isEmpty {
            suggestions = recentSearches + staticSuggestions
            return
        }

        let lower = filter.lowercased()

        let recFiltered = recentSearches.filter {
            $0.lowercased().contains(lower)
        }

        let staticFiltered = staticSuggestions.filter {
            $0.lowercased().contains(lower)
        }

        var combined = recFiltered
        for s in staticFiltered {
            if !combined.contains(where: { $0.caseInsensitiveCompare(s) == .orderedSame }) {
                combined.append(s)
            }
        }
        suggestions = combined
    }
}
