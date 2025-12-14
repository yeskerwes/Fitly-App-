import UIKit
import CoreData
import SnapKit

extension Notification.Name {
    static let challengeStatusChanged = Notification.Name("challengeStatusChanged")
}

class MainViewController: UIViewController {

    // MARK: - Data
    private var itemsEntities: [ChallengeEntity] = []

    private var openedIndexPath: IndexPath?

    // MARK: - Top UI (kept simple)
    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome back,"
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .gray
        return l
    }()

    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.text = "there!"
        l.font = UIFont.boldSystemFont(ofSize: 18)
        return l
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .white
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.systemBackground.cgColor
        return iv
    }()

    private let yourBetsLabel: UILabel = {
        let l = UILabel()
        l.text = "Your bets"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .lightGray
        return l
    }()

    private let infoLabel: UILabel = {
        let l = UILabel()
        l.text = "You don’t have bet yet"
        l.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        l.numberOfLines = 0
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 28
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 40, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ChallengeCell.self, forCellWithReuseIdentifier: ChallengeCell.reuseId)
        cv.dataSource = self
        cv.delegate = self
        cv.alwaysBounceVertical = true
        cv.isHidden = true
        return cv
    }()

    private let createBetButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create the bet", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .app
        b.layer.cornerRadius = 24
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupConstraints()
        setupActions()

        _ = CoreDataManager.shared.persistentContainer

        loadActiveChallenges()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCellPan(_:)))
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)

        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged(_:)), name: .settingsChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Constraints
    private func setupConstraints() {
        [welcomeLabel, usernameLabel, avatarImageView, yourBetsLabel, infoLabel, collectionView, createBetButton].forEach {
            view.addSubview($0)
        }

        welcomeLabel.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(10)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(6)
        }

        usernameLabel.snp.makeConstraints { make in
            make.leading.equalTo(welcomeLabel.snp.leading)
            make.top.equalTo(welcomeLabel.snp.bottom).offset(2)
        }

        avatarImageView.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.centerY.equalTo(welcomeLabel.snp.centerY).offset(8)
            make.width.height.equalTo(44)
        }

        yourBetsLabel.snp.makeConstraints { make in
            make.leading.equalTo(welcomeLabel.snp.leading)
            make.top.equalTo(usernameLabel.snp.bottom).offset(8)
        }

        infoLabel.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(20)
            make.top.equalTo(yourBetsLabel.snp.bottom).offset(12)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.trailing).offset(-20)
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(yourBetsLabel.snp.bottom).offset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        createBetButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-18)
            make.width.equalToSuperview().multipliedBy(0.75)
            make.height.equalTo(55)
        }

        view.bringSubviewToFront(createBetButton)
    }

    // MARK: - Actions
    private func setupActions() {
        createBetButton.addTarget(self, action: #selector(openCreateModal), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openProfile))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tap)
    }

    @objc private func openCreateModal() {
        let modal = ModalBetViewController()
        modal.delegate = self
        modal.modalPresentationStyle = .overFullScreen
        present(modal, animated: true)
    }

    @objc private func openProfile() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }

    // MARK: - Core Data (challenges)
    private func loadActiveChallenges() {
        itemsEntities = CoreDataManager.shared.fetchChallenges(status: "active")
        collectionView.reloadData()
        updateUIForState()
    }

    private func updateUIForState() {
        let isEmpty = itemsEntities.isEmpty
        infoLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty

        createBetButton.isHidden = false

        view.bringSubviewToFront(createBetButton)
    }

    // MARK: - Profile UI update (username & avatar)
    @objc private func settingsChanged(_ notification: Notification) {
        updateProfileUI()
    }

    private func updateProfileUI() {
        let name = CoreDataManager.shared.currentUsername()
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            welcomeLabel.text = "Welcome back,"
            usernameLabel.text = "there!"
        } else {
            welcomeLabel.text = "Welcome back,"
            usernameLabel.text = name
        }

        if let avatar = CoreDataManager.shared.currentAvatarImage() {
            avatarImageView.image = avatar
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.tintColor = nil
        } else {
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarImageView.tintColor = .black
            avatarImageView.contentMode = .scaleAspectFit
            avatarImageView.backgroundColor = .white
        }
    }

    // MARK: - Pan gesture handling for reveal Cancel
    @objc private func handleCellPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        switch gesture.state {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: location),
                  let cell = collectionView.cellForItem(at: indexPath) as? ChallengeCell else {
                return
            }
            if let opened = openedIndexPath, opened != indexPath {
                if let prevCell = collectionView.cellForItem(at: opened) as? ChallengeCell {
                    prevCell.close(animated: true)
                }
                openedIndexPath = nil
            }

            openedIndexPath = indexPath
        case .changed:
            guard let indexPath = collectionView.indexPathForItem(at: location),
                  let cell = collectionView.cellForItem(at: indexPath) as? ChallengeCell else { return }
            let translation = gesture.translation(in: collectionView)
            if translation.x < -30 {
                cell.open(animated: true)
                openedIndexPath = indexPath
                cell.onCancelTapped = { [weak self] in
                    guard let self = self else { return }
                    self.handleCancelAction(at: indexPath)
                }
            } else if translation.x > 30 {
                cell.close(animated: true)
                if openedIndexPath == indexPath { openedIndexPath = nil }
            }
        case .ended, .cancelled, .failed:

            if let idx = openedIndexPath, let cell = collectionView.cellForItem(at: idx) as? ChallengeCell {
                let velocityX = gesture.velocity(in: collectionView).x
                if velocityX < -200 {
                    cell.open(animated: true)
                }
                cell.onCancelTapped = { [weak self] in
                    guard let self = self else { return }
                    self.handleCancelAction(at: idx)
                }
            }
        default:
            break
        }
    }

    // MARK: - Cancel action (mark cancelled + remove from active list)
    private func handleCancelAction(at indexPath: IndexPath) {
        guard indexPath.item < itemsEntities.count else { return }
        let entity = itemsEntities[indexPath.item]

        CoreDataManager.shared.updateStatus(for: entity, to: "cancelled")

        itemsEntities.remove(at: indexPath.item)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.updateUIForState()
        })

        if openedIndexPath == indexPath { openedIndexPath = nil }

        NotificationCenter.default.post(name: .challengeStatusChanged, object: nil, userInfo: ["id": entity.id as Any, "status": "cancelled"])
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedEntity = itemsEntities[indexPath.item]
        let vc = ChallengeDetailViewController(entity: selectedEntity)
        navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        itemsEntities.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChallengeCell.reuseId, for: indexPath) as? ChallengeCell else {
            return UICollectionViewCell()
        }
        let entity = itemsEntities[indexPath.item]
        cell.configure(with: entity)
        cell.onCancelTapped = { [weak self] in
            guard let self = self else { return }
            self.handleCancelAction(at: indexPath)
        }
        
        cell.close(animated: false)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: 240)
    }
}

// MARK: - UIPan Gesture Delegate (allow simultaneous scroll + pan)
extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Modal Delegate (Modal should return created ChallengeEntity)
extension MainViewController: ModalBetViewControllerDelegate {
    func modalBetViewController(_ controller: ModalBetViewController, didCreate entity: ChallengeEntity) {
        controller.dismiss(animated: true) {
            self.loadActiveChallenges()
        }
    }

    func modalBetViewControllerDidCancel(_ controller: ModalBetViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

