//
//  YouTubeService.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 14.12.2025.
//

import Foundation

protocol YouTubeServiceProtocol {
    func search(query: String, maxResults: Int) async throws -> [VideoItem]
}

final class YouTubeService: YouTubeServiceProtocol {

    static let shared = YouTubeService()
    private init() {}

    func search(query: String, maxResults: Int = 12) async throws -> [VideoItem] {
        try await YouTubeAPI.shared.searchVideos(
            query: query,
            maxResults: maxResults
        )
    }
}
