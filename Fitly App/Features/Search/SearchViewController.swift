//
//  SearchViewController.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 12.12.2025.
//

import UIKit
import SafariServices

final class SearchViewController: UIViewController {

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let searchButton = UIButton(type: .system)
    private let tableView = UITableView()

    // MARK: - Data
    private var videoResults: [VideoItem] = []

    private var suggestions: [String] = []
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

    private var recentSearches: [String] {
        get { UserDefaults.standard.stringArray(forKey: "recent_searches") ?? [] }
        set { UserDefaults.standard.setValue(newValue, forKey: "recent_searches") }
    }

    private var showingSuggestions = true

    private var debounceWorkItem: DispatchWorkItem?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        setupViews()
        reloadSuggestions(filter: "")
    }

    // MARK: - Setup Views
    private func setupViews() {
        searchBar.placeholder = "Search YouTube for exercise technique"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)

        searchButton.setTitle("Search", for: .normal)
        searchButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(handleSearchTapped), for: .touchUpInside)
        view.addSubview(searchButton)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(VideoCell.self, forCellReuseIdentifier: VideoCell.reuseId)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestion")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            searchBar.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),

            searchButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 8),
            searchButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            searchButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 80),

            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func handleSearchTapped() {
        searchBar.resignFirstResponder()
        let text = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { showEmptyQueryAlert(); return }
        saveRecentSearch(text)
        performSearch(query: text)
    }

    private func performSearch(query: String) {
        showingSuggestions = false
        tableView.reloadData()

        let spinner = UIActivityIndicatorView(style: .medium)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        spinner.startAnimating()

        Task {
            do {
                let items = try await YouTubeAPI.shared.searchVideos(query: query, maxResults: 12)
                DispatchQueue.main.async { [weak self] in
                    spinner.stopAnimating()
                    self?.navigationItem.rightBarButtonItem = nil
                    self?.videoResults = items
                    self?.tableView.reloadData()
                    if items.isEmpty { self?.showNoResultsLabel() }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    spinner.stopAnimating()
                    self?.navigationItem.rightBarButtonItem = nil
                    self?.showError(error)
                }
            }
        }
    }

    // MARK: - Suggestions logic
    private func reloadSuggestions(filter: String) {
        let recents = recentSearches
        if filter.isEmpty {
            suggestions = recents + staticSuggestions
        } else {
            let lower = filter.lowercased()
            let recFiltered = recents.filter { $0.lowercased().contains(lower) }
            let staticFiltered = staticSuggestions.filter { $0.lowercased().contains(lower) }
            var combined = recFiltered
            for s in staticFiltered {
                if !combined.contains(where: { $0.caseInsensitiveCompare(s) == .orderedSame }) {
                    combined.append(s)
                }
            }
            suggestions = combined
        }
        showingSuggestions = true
        tableView.reloadData()
    }

    private func saveRecentSearch(_ text: String) {
        var list = recentSearches
        list.removeAll { $0.caseInsensitiveCompare(text) == .orderedSame }
        list.insert(text, at: 0)
        if list.count > 10 { list = Array(list.prefix(10)) }
        recentSearches = list
    }

    // MARK: - UI Helpers
    private func showEmptyQueryAlert() {
        let a = UIAlertController(title: "Empty query", message: "Please type what you want to search.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func showNoResultsLabel() {
        let a = UIAlertController(title: "No results", message: "Try another query or choose a suggestion.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func showError(_ error: Error) {
        let msg: String
        if let yErr = error as? YouTubeError {
            switch yErr {
            case .badURL: msg = "Bad request URL."
            case .badResponse(let code, let details): msg = "Server returned \(code). \(details ?? "")"
            case .noData: msg = "No data received."
            case .decodeError(let s): msg = "Decode error: \(s)"
            }
        } else {
            msg = error.localizedDescription
        }
        let a = UIAlertController(title: "Search error", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        debounceWorkItem?.cancel()
        let current = DispatchWorkItem { [weak self] in
            self?.reloadSuggestions(filter: searchText)
        }
        debounceWorkItem = current
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: current)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        handleSearchTapped()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        reloadSuggestions(filter: "")
    }
}

// MARK: - TableView
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showingSuggestions ? suggestions.count : videoResults.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return showingSuggestions ? (recentSearches.isEmpty ? "Suggestions" : "Recent · Suggestions") : "Results"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if showingSuggestions {
            let cell = tableView.dequeueReusableCell(withIdentifier: "suggestion", for: indexPath)
            let text = suggestions[indexPath.row]
            cell.textLabel?.text = text
            cell.textLabel?.textColor = .label
            cell.imageView?.image = UIImage(systemName: "magnifyingglass")
            cell.accessoryType = .none
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.reuseId, for: indexPath) as? VideoCell else {
                return UITableViewCell()
            }
            let item = videoResults[indexPath.row]
            cell.configure(with: item)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if showingSuggestions {
            let text = suggestions[indexPath.row]
            searchBar.text = text
            saveRecentSearch(text)
            performSearch(query: text)
        } else {
            let item = videoResults[indexPath.row]
            if let url = URL(string: "https://www.youtube.com/watch?v=\(item.videoId)") {
                let vc = SFSafariViewController(url: url)
                present(vc, animated: true)
            }
        }
    }
}
