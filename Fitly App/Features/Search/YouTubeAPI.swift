//
//  YouTubeAPI.swift
//  Fitly App
//
//  Created by Assistant-mod on behalf of user
//

import Foundation

enum YouTubeError: Error {
    case badURL
    case badResponse(Int, String?)
    case noData
    case decodeError(String)
}

final class YouTubeAPI {
    static let shared = YouTubeAPI()
    private init() {}

    // ---- Хардкодим API key прямо в коде (замени на свой ключ) ----
    private let apiKey = "AIzaSyCi6u2j3nYKJ3t8lXB0wbAZZYcYRJnBEjY"

    private let base = "https://www.googleapis.com/youtube/v3"

    /// Search videos by query using `search.list` endpoint
    func searchVideos(query: String, maxResults: Int = 12) async throws -> [VideoItem] {
        guard var comps = URLComponents(string: "\(base)/search") else { throw YouTubeError.badURL }

        comps.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = comps.url else { throw YouTubeError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Лог для отладки: URL и факт, что ключ не пустой
        print("[YouTubeAPI] Request URL: \(url.absoluteString)")
        print("[YouTubeAPI] API key present: \(!apiKey.isEmpty)")

        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw YouTubeError.badResponse(-1, nil) }

        if !(200..<300).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("[YouTubeAPI] ERROR status: \(http.statusCode). Body: \(bodyString)")

            if let ytErr = try? JSONDecoder().decode(YouTubeAPIErrorResponse.self, from: data) {
                throw YouTubeError.badResponse(http.statusCode, ytErr.error.message)
            } else {
                throw YouTubeError.badResponse(http.statusCode, bodyString)
            }
        }

        guard data.count > 0 else { throw YouTubeError.noData }

        do {
            let decoded = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return decoded.items.map { item in
                VideoItem(
                    videoId: item.id.videoId,
                    title: item.snippet.title,
                    description: item.snippet.description,
                    thumbnailURL: item.snippet.thumbnails.medium?.url ?? item.snippet.thumbnails.default?.url
                )
            }
        } catch {
            throw YouTubeError.decodeError(error.localizedDescription)
        }
    }
}

// MARK: - YouTube response models
struct YouTubeSearchResponse: Codable {
    let items: [YTSearchItem]
}

struct YTSearchItem: Codable {
    let id: YTId
    let snippet: YTSnippet
}

struct YTId: Codable {
    let kind: String?
    let videoId: String
}

struct YTSnippet: Codable {
    let title: String
    let description: String
    let thumbnails: YTThumbnails
}

struct YTThumbnails: Codable {
    let `default`: YTThumbnail?
    let medium: YTThumbnail?
    let high: YTThumbnail?
}

struct YTThumbnail: Codable {
    let url: URL
    let width: Int?
    let height: Int?
}

// UI model
struct VideoItem: Identifiable {
    let id = UUID()
    let videoId: String
    let title: String
    let description: String
    let thumbnailURL: URL?
}

// YouTube API error response (частичная модель)
private struct YouTubeAPIErrorResponse: Codable {
    struct Err: Codable {
        let code: Int
        let message: String
    }
    let error: Err
}
