import UIKit
import SnapKit

extension Notification.Name {
    static let challengeStatusChanged = Notification.Name("challengeStatusChanged")
}

final class MainViewController: UIViewController {

    // MARK: - Architecture
    private let presenter = MainPresenter()

    // MARK: - Data
    private var itemsEntities: [ChallengeEntity] = []
    private var openedIndexPath: IndexPath?

    // MARK: - UI
    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome back,"
        l.font = UIFont(name: "Poppins-Regular", size: 16)
        l.textColor = .gray
        return l
    }()

    private let usernameLabel: UILabel = {
        let l = UILabel()
        l.text = "there!"
        l.font = UIFont(name: "Poppins-Bold", size: 18)
        return l
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.systemBackground.cgColor
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let yourBetsLabel: UILabel = {
        let l = UILabel()
        l.text = "Your challenges"
        l.font = UIFont(name: "Poppins-Regular", size: 14)
        l.textColor = .lightGray
        return l
    }()

    private let infoLabel: UILabel = {
        let l = UILabel()
        l.text = "You don’t have challenge yet"
        l.font = UIFont(name: "Poppins-SemiBold", size: 36)
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
        cv.isHidden = true
        return cv
    }()

    private let createBetButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create the bet", for: .normal)
        b.titleLabel?.font = UIFont(name: "Poppins-Medium", size: 20)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .app
        b.layer.cornerRadius = 24
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupLayout()
        setupActions()
        loadActiveChallenges()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCellPan(_:)))
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateProfileUI),
            name: .settingsChanged,
            object: nil
        )
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

    // MARK: - Setup
    private func setupLayout() {
        [welcomeLabel, usernameLabel, avatarImageView,
         yourBetsLabel, infoLabel, collectionView, createBetButton]
            .forEach { view.addSubview($0) }

        welcomeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(70)
        }

        usernameLabel.snp.makeConstraints {
            $0.leading.equalTo(welcomeLabel)
            $0.top.equalTo(welcomeLabel.snp.bottom).offset(2)
        }

        avatarImageView.snp.makeConstraints {
            $0.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.centerY.equalTo(welcomeLabel).offset(8)
            $0.size.equalTo(44)
        }

        yourBetsLabel.snp.makeConstraints {
            $0.leading.equalTo(welcomeLabel)
            $0.top.equalTo(usernameLabel.snp.bottom).offset(8)
        }

        infoLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalTo(yourBetsLabel.snp.bottom).offset(12)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        collectionView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(yourBetsLabel.snp.bottom).offset(8)
        }

        createBetButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-18)
            $0.width.equalToSuperview().multipliedBy(0.75)
            $0.height.equalTo(55)
        }
    }

    private func setupActions() {
        createBetButton.addTarget(self, action: #selector(openCreateModal), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openProfile))
        avatarImageView.addGestureRecognizer(tap)
    }

    // MARK: - Data
    private func loadActiveChallenges() {
        itemsEntities = presenter.loadChallenges()
        collectionView.reloadData()
        updateUIForState()
    }

    private func updateUIForState() {
        let empty = itemsEntities.isEmpty
        infoLabel.isHidden = !empty
        collectionView.isHidden = empty
    }

    @objc private func updateProfileUI() {
        let info = presenter.profileInfo()
        usernameLabel.text = info.name.isEmpty ? "there!" : info.name
        avatarImageView.image = info.avatar ?? UIImage(systemName: "person.crop.circle.fill")
    }

    // MARK: - Navigation
    @objc private func openCreateModal() {
        let modal = ModalBetViewController()
        modal.delegate = self
        modal.modalPresentationStyle = .overFullScreen
        present(modal, animated: true)
    }

    @objc private func openProfile() {
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }

    // MARK: - Cancel logic
    private func handleCancelAction(at indexPath: IndexPath) {
        let entity = itemsEntities[indexPath.item]
        presenter.cancelChallenge(entity)

        itemsEntities.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        updateUIForState()

        NotificationCenter.default.post(
            name: .challengeStatusChanged,
            object: nil,
            userInfo: ["id": entity.id as Any, "status": "cancelled"]
        )
    }
}

// MARK: - CollectionView
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        itemsEntities.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChallengeCell.reuseId,
            for: indexPath
        ) as! ChallengeCell

        let entity = itemsEntities[indexPath.item]
        cell.configure(with: entity)
        cell.onCancelTapped = { [weak self] in
            self?.handleCancelAction(at: indexPath)
        }
        cell.close(animated: false)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let vc = ChallengeDetailViewController(entity: itemsEntities[indexPath.item])
        navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 240)
    }
}

// MARK: - Gesture
extension MainViewController: UIGestureRecognizerDelegate {
    @objc private func handleCellPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let cell = collectionView.cellForItem(at: indexPath) as? ChallengeCell else { return }

        let translation = gesture.translation(in: collectionView)
        if translation.x < -30 {
            cell.open(animated: true)
        } else if translation.x > 30 {
            cell.close(animated: true)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

// MARK: - Modal Delegate
extension MainViewController: ModalBetViewControllerDelegate {
    func modalBetViewController(_ controller: ModalBetViewController,
                                didCreate entity: ChallengeEntity) {
        controller.dismiss(animated: true) {
            self.loadActiveChallenges()
        }
    }

    func modalBetViewControllerDidCancel(_ controller: ModalBetViewController) {
        controller.dismiss(animated: true)
    }
}
