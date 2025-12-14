import UIKit
import CoreData
import SnapKit

class HistoryViewController: UIViewController {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "History"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return l
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private var historyItems: [ChallengeEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupConstraints()
        setupTable()
        loadHistory()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(historyNeedsReload(_:)),
            name: .challengeStatusChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupConstraints() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
        }

        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupTable() {
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 84
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16 + 56 + 12, bottom: 0, right: 0)
    }

    func loadHistory() {
        let completed = CoreDataManager.shared.fetchChallenges(status: "completed")
        let cancelled = CoreDataManager.shared.fetchChallenges(status: "cancelled")

        historyItems = (completed + cancelled).sorted { a, b in
            let dateA = preferredHistoryDate(for: a) ?? .distantPast
            let dateB = preferredHistoryDate(for: b) ?? .distantPast
            return dateA > dateB
        }

        tableView.reloadData()
    }

    @objc private func historyNeedsReload(_ notification: Notification) {
        loadHistory()
    }

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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        historyItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let entity = historyItems[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryCell.reuseId,
            for: indexPath
        ) as? HistoryCell else {
            return UITableViewCell()
        }

        cell.configure(with: entity)
        return cell
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            let entity = historyItems[indexPath.row]
            CoreDataManager.shared.delete(entity)
            historyItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entity = historyItems[indexPath.row]
        let vc = ChallengeDetailViewController(entity: entity)
        navigationController?.pushViewController(vc, animated: true)
    }
}
