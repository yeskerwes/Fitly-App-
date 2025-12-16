import UIKit
import SnapKit

final class HistoryViewController: UIViewController {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "History"
        l.font = UIFont(name: "Poppins-SemiBold", size: 20)
        return l
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private var historyItems: [ChallengeEntity] = []
    private let service = HistoryService.shared

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
            make.leading.equalToSuperview().offset(160)
            make.top.equalToSuperview().offset(70)
        }

        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupTable() {
        tableView.register(HistoryViewCell.self,
                           forCellReuseIdentifier: HistoryViewCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 84
        tableView.separatorInset =
            UIEdgeInsets(top: 0, left: 16 + 56 + 12, bottom: 0, right: 0)
    }

    private func loadHistory() {
        historyItems = service.loadHistory()
        tableView.reloadData()
    }

    @objc private func historyNeedsReload(_ notification: Notification) {
        loadHistory()
    }
}

// MARK: - UITableView DataSource / Delegate
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        historyItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let entity = historyItems[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryViewCell.reuseId,
            for: indexPath
        ) as? HistoryViewCell else {
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
            service.delete(entity)
            historyItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let entity = historyItems[indexPath.row]
        let vc = ChallengeDetailViewController(entity: entity)
        navigationController?.pushViewController(vc, animated: true)
    }
}
