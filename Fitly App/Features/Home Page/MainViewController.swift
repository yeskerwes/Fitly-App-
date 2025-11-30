import UIKit
import CoreData

// Notification name used to inform History to reload
extension Notification.Name {
    static let challengeStatusChanged = Notification.Name("challengeStatusChanged")
    // settingsChanged defined in CoreDataManager.swift
}

class MainViewController: UIViewController {

    // MARK: - Data
    private var itemsEntities: [ChallengeEntity] = []

    // Track which indexPath cell is currently opened (revealed Cancel)
    private var openedIndexPath: IndexPath?

    // MARK: - Top UI (kept simple)
    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome back,"
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .gray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.text = "there!"
        l.font = UIFont.boldSystemFont(ofSize: 18)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Avatar image shown in top-right
    private let avatarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .white
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.systemBackground.cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let yourBetsLabel: UILabel = {
        let l = UILabel()
        l.text = "Your bets"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .lightGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Empty state UI
    private let infoLabel: UILabel = {
        let l = UILabel()
        l.text = "You don’t have bet yet"
        l.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Collection (cards)
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
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let createBetButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create the bet", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .app
        b.layer.cornerRadius = 24
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupActions()

        // preload Core Data container so context ready
        _ = CoreDataManager.shared.persistentContainer

        // load active items
        loadActiveChallenges()

        // add pan gesture for reveal/cancel
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCellPan(_:)))
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)

        // observe settings changes (username / avatar)
        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged(_:)), name: .settingsChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // make avatar circular
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout
    private func setupLayout() {
        [welcomeLabel, usernameLabel, avatarImageView, yourBetsLabel, infoLabel, collectionView, createBetButton].forEach {
            view.addSubview($0)
        }

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // welcome + username stacked on the left
            welcomeLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            welcomeLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 6),

            usernameLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 2),

            // avatar on the right aligned with welcome
            avatarImageView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            avatarImageView.centerYAnchor.constraint(equalTo: welcomeLabel.centerYAnchor, constant: 8),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            // yourBets label below username
            yourBetsLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            yourBetsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),

            // infoLabel (empty state)
            infoLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            infoLabel.topAnchor.constraint(equalTo: yourBetsLabel.bottomAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -20),

            // collectionView pinned under yourBetsLabel
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: yourBetsLabel.bottomAnchor, constant: 8),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            // create button
            createBetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createBetButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -18),
            createBetButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            createBetButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        createBetButton.addTarget(self, action: #selector(openCreateModal), for: .touchUpInside)

        // allow tapping avatar to open profile (optional)
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

        // кнопка всегда видима
        createBetButton.isHidden = false

        // на всякий случай держим её сверху
        view.bringSubviewToFront(createBetButton)
    }

    // MARK: - Profile UI update (username & avatar)
    @objc private func settingsChanged(_ notification: Notification) {
        // called when profile saved (CoreDataManager posts .settingsChanged)
        updateProfileUI()
    }

    private func updateProfileUI() {
        // Username
        let name = CoreDataManager.shared.currentUsername()
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            welcomeLabel.text = "Welcome back,"
            usernameLabel.text = "there!"
        } else {
            welcomeLabel.text = "Welcome back,"
            usernameLabel.text = name
        }

        // Avatar
        if let avatar = CoreDataManager.shared.currentAvatarImage() {
            avatarImageView.image = avatar
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.tintColor = nil
        } else {
            // fallback system icon (matches Profile UI)
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

            // close previously opened cell
            if let opened = openedIndexPath, opened != indexPath {
                if let prevCell = collectionView.cellForItem(at: opened) as? ChallengeCell {
                    prevCell.close(animated: true)
                }
                openedIndexPath = nil
            }

            openedIndexPath = indexPath
            // no immediate open — wait for movement
        case .changed:
            guard let indexPath = collectionView.indexPathForItem(at: location),
                  let cell = collectionView.cellForItem(at: indexPath) as? ChallengeCell else { return }
            let translation = gesture.translation(in: collectionView)
            if translation.x < -30 {
                cell.open(animated: true)
                openedIndexPath = indexPath
                // set cancel handler
                cell.onCancelTapped = { [weak self] in
                    guard let self = self else { return }
                    self.handleCancelAction(at: indexPath)
                }
            } else if translation.x > 30 {
                cell.close(animated: true)
                if openedIndexPath == indexPath { openedIndexPath = nil }
            }
        case .ended, .cancelled, .failed:
            // if a cell is opened, ensure its handler is set (in case user lifted finger)
            if let idx = openedIndexPath, let cell = collectionView.cellForItem(at: idx) as? ChallengeCell {
                let velocityX = gesture.velocity(in: collectionView).x
                if velocityX < -200 {
                    cell.open(animated: true)
                }
                // ensure handler
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

        // Update Core Data
        CoreDataManager.shared.updateStatus(for: entity, to: "cancelled")

        // Remove from local array and animate deletion
        itemsEntities.remove(at: indexPath.item)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.updateUIForState()
        })

        // clear opened index
        if openedIndexPath == indexPath { openedIndexPath = nil }

        // Notify history to reload
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

        // ensure closure is set (in case cell reused)
        cell.onCancelTapped = { [weak self] in
            guard let self = self else { return }
            self.handleCancelAction(at: indexPath)
        }

        // ensure closed by default
        cell.close(animated: false)
        return cell
    }

    // card size — wide cards with internal paddings
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
