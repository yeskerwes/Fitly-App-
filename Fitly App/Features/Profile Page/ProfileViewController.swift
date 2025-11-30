import UIKit

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

    // rest of UI (appearance/notifications/reset) reuse previous layout...
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
        setupViews()
        setupActions()
        loadSettings()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerImageView)

        view.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(cameraBadge)
        cameraBadge.addSubview(cameraIcon)

        view.addSubview(nameLabel)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(sectionProfileTitle)
        contentView.addSubview(nameTextField)
        contentView.addSubview(nameUnderline)
        contentView.addSubview(saveButton)

        contentView.addSubview(sectionAppearanceTitle)
        contentView.addSubview(changeThemeLabel)

        contentView.addSubview(sectionNotificationsTitle)
        contentView.addSubview(notificationsLabel)
        contentView.addSubview(notificationsSwitch)

        contentView.addSubview(resetButton)
        contentView.addSubview(bottomSpacer)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // header
            headerImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 180),

            // avatar
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -64),
            avatarContainer.widthAnchor.constraint(equalToConstant: 128),
            avatarContainer.heightAnchor.constraint(equalToConstant: 128),

            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalTo: avatarContainer.widthAnchor),
            avatarImageView.heightAnchor.constraint(equalTo: avatarContainer.heightAnchor),

            cameraBadge.widthAnchor.constraint(equalToConstant: 32),
            cameraBadge.heightAnchor.constraint(equalToConstant: 32),
            cameraBadge.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 6),
            cameraBadge.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 6),

            cameraIcon.centerXAnchor.constraint(equalTo: cameraBadge.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: cameraBadge.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 16),
            cameraIcon.heightAnchor.constraint(equalToConstant: 16),

            // name
            nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // scroll
            scrollView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Profile section
            sectionProfileTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            sectionProfileTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            nameTextField.topAnchor.constraint(equalTo: sectionProfileTitle.bottomAnchor, constant: 16),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 36),

            nameUnderline.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 6),
            nameUnderline.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            nameUnderline.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            nameUnderline.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: nameUnderline.bottomAnchor, constant: 12),
            saveButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),

            // Appearance
            sectionAppearanceTitle.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 24),
            sectionAppearanceTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            changeThemeLabel.topAnchor.constraint(equalTo: sectionAppearanceTitle.bottomAnchor, constant: 16),
            changeThemeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // Notifications
            sectionNotificationsTitle.topAnchor.constraint(equalTo: changeThemeLabel.bottomAnchor, constant: 24),
            sectionNotificationsTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            notificationsLabel.topAnchor.constraint(equalTo: sectionNotificationsTitle.bottomAnchor, constant: 16),
            notificationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            notificationsSwitch.centerYAnchor.constraint(equalTo: notificationsLabel.centerYAnchor),
            notificationsSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Reset
            resetButton.topAnchor.constraint(equalTo: notificationsLabel.bottomAnchor, constant: 36),
            resetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            bottomSpacer.topAnchor.constraint(equalTo: resetButton.bottomAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 40),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setupActions() {
        // avatar tap
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
            // show system icon if no avatar
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarImageView.tintColor = .black
            avatarImageView.contentMode = .scaleAspectFit
            avatarImageView.backgroundColor = .white
        }
    }

    @objc private func saveTapped() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        CoreDataManager.shared.saveUsername(name)
        // feedback
        let alert = UIAlertController(title: nil, message: "Saved", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            alert.dismiss(animated: true, completion: nil)
        }
        // update name label
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
        // Optionally resize before saving to limit size
        let resized = image.scaledTo(maxDimension: 1024)
        CoreDataManager.shared.saveAvatarImage(resized)
        loadSettings()
    }
}

// Simple image resize helper
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
