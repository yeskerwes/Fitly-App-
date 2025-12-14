import UIKit
import SnapKit

class ProfileViewController: UIViewController {

    // MARK: - Header (оставляем как в UI)
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .app
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Avatar
    private let avatarContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.crop.circle.fill")
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .white
        iv.layer.borderWidth = 6
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
    }()

    private let cameraBadge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.18, green: 0.78, blue: 0.48, alpha: 1)
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 3
        v.layer.borderColor = UIColor.white.cgColor
        return v
    }()

    private let cameraIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "camera.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Name & UI elements
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.text = "Name"
        l.font = UIFont.boldSystemFont(ofSize: 32)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter name"
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let nameUnderline: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let sectionProfileTitle: UILabel = {
        let l = UILabel(); l.text = "Profile"; l.font = UIFont.systemFont(ofSize: 18, weight: .semibold); l.textColor = .systemGray; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let sectionAppearanceTitle: UILabel = {
        let l = UILabel(); l.text = "Appearance"; l.font = UIFont.systemFont(ofSize: 18, weight: .semibold); l.textColor = .systemGray; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let changeThemeLabel: UILabel = {
        let l = UILabel(); l.text = "Change Theme"; l.font = UIFont.systemFont(ofSize: 16); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let sectionNotificationsTitle: UILabel = {
        let l = UILabel(); l.text = "Notifications"; l.font = UIFont.systemFont(ofSize: 18, weight: .semibold); l.textColor = .systemGray; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let notificationsLabel: UILabel = {
        let l = UILabel(); l.text = "Enable Notifications"; l.font = UIFont.systemFont(ofSize: 16); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let notificationsSwitch: UISwitch = {
        let s = UISwitch(); s.isOn = true; s.onTintColor = UIColor(red: 0.18, green: 0.78, blue: 0.48, alpha: 1); s.translatesAutoresizingMaskIntoConstraints = false; return s
    }()
    private let resetButton: UIButton = {
        let b = UIButton(type: .system); b.setTitle("Reset Settings", for: .normal); b.setTitleColor(.systemRed, for: .normal); b.titleLabel?.font = UIFont.systemFont(ofSize: 18); b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let bottomSpacer: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()

    // MARK: - Lifecycle & setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupConstraints()
        setupActions()
        loadSettings()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    // MARK: - Setup Views
    private func setupConstraints() {

        view.addSubview(headerImageView)
        view.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(cameraBadge)
        cameraBadge.addSubview(cameraIcon)
        view.addSubview(nameLabel)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            sectionProfileTitle,
            nameTextField,
            nameUnderline,
            saveButton,
            sectionAppearanceTitle,
            changeThemeLabel,
            sectionNotificationsTitle,
            notificationsLabel,
            notificationsSwitch,
            resetButton,
            bottomSpacer
        ].forEach { contentView.addSubview($0) }

        headerImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(180)
        }

        avatarContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(headerImageView.snp.bottom).offset(-64)
            $0.size.equalTo(128)
        }

        avatarImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        cameraBadge.snp.makeConstraints {
            $0.size.equalTo(32)
            $0.trailing.bottom.equalToSuperview().offset(6)
        }

        cameraIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(16)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarContainer.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        sectionProfileTitle.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(20)
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(sectionProfileTitle.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        nameUnderline.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(6)
            $0.leading.trailing.equalTo(nameTextField)
            $0.height.equalTo(1)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(nameUnderline.snp.bottom).offset(12)
            $0.trailing.equalTo(nameTextField)
        }

        sectionAppearanceTitle.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
        }

        changeThemeLabel.snp.makeConstraints {
            $0.top.equalTo(sectionAppearanceTitle.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
        }

        sectionNotificationsTitle.snp.makeConstraints {
            $0.top.equalTo(changeThemeLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
        }

        notificationsLabel.snp.makeConstraints {
            $0.top.equalTo(sectionNotificationsTitle.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
        }

        notificationsSwitch.snp.makeConstraints {
            $0.centerY.equalTo(notificationsLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        resetButton.snp.makeConstraints {
            $0.top.equalTo(notificationsLabel.snp.bottom).offset(36)
            $0.leading.equalToSuperview().offset(20)
        }

        bottomSpacer.snp.makeConstraints {
            $0.top.equalTo(resetButton.snp.bottom)
            $0.height.equalTo(40)
            $0.bottom.equalToSuperview()
        }
    }

    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tap)

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    // MARK: - Load / Save
    private func loadSettings() {
        let name = CoreDataManager.shared.currentUsername()
        nameLabel.text = name.isEmpty ? " " : name
        nameTextField.text = name

        if let img = CoreDataManager.shared.currentAvatarImage() {
            avatarImageView.image = img
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.tintColor = nil
        } else {
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarImageView.tintColor = .black
            avatarImageView.contentMode = .scaleAspectFit
            avatarImageView.backgroundColor = .white
        }
    }

    @objc private func saveTapped() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        CoreDataManager.shared.saveUsername(name)
        let alert = UIAlertController(title: nil, message: "Saved", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            alert.dismiss(animated: true, completion: nil)
        }
        nameLabel.text = name
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Avatar picker
    @objc private func avatarTapped() {
        let alert = UIAlertController(title: "Change Avatar", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.presentImagePicker(source: .camera)
            })
        }
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentImagePicker(source: .photoLibrary)
        })
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            CoreDataManager.shared.saveAvatarImage(nil)
            self.loadSettings()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
}

// MARK: - Image picker delegate
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        var chosen: UIImage?
        if let edited = info[.editedImage] as? UIImage {
            chosen = edited
        } else if let original = info[.originalImage] as? UIImage {
            chosen = original
        }
        guard let image = chosen else { return }
        let resized = image.scaledTo(maxDimension: 1024)
        CoreDataManager.shared.saveAvatarImage(resized)
        loadSettings()
    }
}

private extension UIImage {
    func scaledTo(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? self
    }
}
