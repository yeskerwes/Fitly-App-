//
//  SearchViewController.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 12.12.2025.
//

import UIKit
import SafariServices
import SnapKit

final class SearchViewController: UIViewController {

    // MARK: - UI
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search YouTube for exercise technique"
        sb.searchBarStyle = .minimal
        return sb
    }()

    private let searchButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Search", for: .normal)
        b.tintColor = .app
        b.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16)
        return b
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.tableFooterView = UIView()
        return tv
    }()

    // MARK: - Architecture
    private let viewModel = SearchViewModel()

    // MARK: - State
    private var showingSuggestions = true
    private var debounceWorkItem: DispatchWorkItem?

    private var recentSearches: [String] {
        get { UserDefaults.standard.stringArray(forKey: "recent_searches") ?? [] }
        set { UserDefaults.standard.setValue(newValue, forKey: "recent_searches") }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search"
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont(name: "Poppins-SemiBold", size: 20)!
        ]
        setupViews()
        setupConstraints()
        reloadSuggestions(filter: "")
    }

    // MARK: - Setup
    private func setupViews() {
        searchBar.delegate = self
        searchButton.addTarget(self, action: #selector(handleSearchTapped), for: .touchUpInside)

        tableView.register(VideoCell.self, forCellReuseIdentifier: VideoCell.reuseId)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestion")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(searchBar)
        view.addSubview(searchButton)
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        searchBar.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
        }

        searchButton.snp.makeConstraints { make in
            make.leading.equalTo(searchBar.snp.trailing).offset(8)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-16)
            make.centerY.equalTo(searchBar.snp.centerY)
            make.width.equalTo(80)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(12)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Actions
    @objc private func handleSearchTapped() {
        searchBar.resignFirstResponder()

        let text = (searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            showAlert(title: "Empty query", message: "Please type what you want to search.")
            return
        }

        saveRecentSearch(text)
        performSearch(query: text)
    }

    private func performSearch(query: String) {
        showingSuggestions = false
        tableView.reloadData()

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)

        Task {
            do {
                try await viewModel.search(query: query)
                DispatchQueue.main.async {
                    spinner.stopAnimating()
                    self.navigationItem.rightBarButtonItem = nil
                    self.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    spinner.stopAnimating()
                    self.navigationItem.rightBarButtonItem = nil
                    self.showAlert(title: "Search error", message: error.localizedDescription)
                }
            }
        }
    }

    private func reloadSuggestions(filter: String) {
        viewModel.reloadSuggestions(
            filter: filter,
            recentSearches: recentSearches
        )
        showingSuggestions = true
        tableView.reloadData()
    }

    private func saveRecentSearch(_ text: String) {
        var list = recentSearches
        list.removeAll { $0.caseInsensitiveCompare(text) == .orderedSame }
        list.insert(text, at: 0)
        recentSearches = Array(list.prefix(10))
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        debounceWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            self?.reloadSuggestions(filter: searchText)
        }

        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        handleSearchTapped()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showingSuggestions
            ? viewModel.suggestions.count
            : viewModel.results.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if showingSuggestions {
            let cell = tableView.dequeueReusableCell(withIdentifier: "suggestion", for: indexPath)
            cell.textLabel?.text = viewModel.suggestions[indexPath.row]
            cell.imageView?.image = UIImage(systemName: "magnifyingglass")
            cell.tintColor = .app
            cell.accessoryType = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: VideoCell.reuseId,
            for: indexPath
        ) as! VideoCell

        cell.configure(with: viewModel.results[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if showingSuggestions {
            let text = viewModel.suggestions[indexPath.row]
            searchBar.text = text
            saveRecentSearch(text)
            performSearch(query: text)
        } else {
            let item = viewModel.results[indexPath.row]
            if let url = URL(string: "https://www.youtube.com/watch?v=\(item.videoId)") {
                present(SFSafariViewController(url: url), animated: true)
            }
        }
    }
}
