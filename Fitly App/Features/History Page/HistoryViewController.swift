import UIKit
import CoreData

class HistoryViewController: UIViewController {

    // UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "History"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)

    // Data
    private var historyItems: [ChallengeEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupTable()
        loadHistory()

        // Reload when challenges change status (completed/cancelled/updated)
        NotificationCenter.default.addObserver(self, selector: #selector(historyNeedsReload(_:)), name: .challengeStatusChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
    }

    private func setupTable() {
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 84 // enough for 56px thumbnail + paddings
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16 + 56 + 12, bottom: 0, right: 0) // align separator under text
    }

    // fetch completed + cancelled
    func loadHistory() {
        // fetch completed and cancelled statuses
        let completed = CoreDataManager.shared.fetchChallenges(status: "completed")
        let cancelled = CoreDataManager.shared.fetchChallenges(status: "cancelled")
        // combine and sort by most recent relevant date
        historyItems = (completed + cancelled).sorted { a, b in
            let dateA = preferredHistoryDate(for: a) ?? Date.distantPast
            let dateB = preferredHistoryDate(for: b) ?? Date.distantPast
            return dateA > dateB
        }
        tableView.reloadData()
    }

    @objc private func historyNeedsReload(_ notification: Notification) {
        // If notification includes id/status, we still reload to keep UI simple
        loadHistory()
    }

    // Helper: pick completedAt if present, else createdAt
    private func preferredHistoryDate(for entity: ChallengeEntity) -> Date? {
        if entity.entity.attributesByName.keys.contains("completedAt"),
           let d = entity.value(forKey: "completedAt") as? Date {
            return d
        }
        return entity.createdAt
    }
}

// MARK: - UITableView DataSource / Delegate
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        historyItems.count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let e = historyItems[indexPath.row]
        guard let cell = tv.dequeueReusableCell(withIdentifier: HistoryCell.reuseId, for: indexPath) as? HistoryCell else {
            return UITableViewCell()
        }
        cell.configure(with: e)
        return cell
    }

    // swipe to permanently delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let e = historyItems[indexPath.row]
            CoreDataManager.shared.delete(e)
            historyItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // optional: tap to view details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entity = historyItems[indexPath.row]
        let vc = ChallengeDetailViewController(entity: entity)
        navigationController?.pushViewController(vc, animated: true)
    }
}
