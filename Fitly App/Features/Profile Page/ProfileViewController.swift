import UIKit
import SnapKit

final class ProfileViewController: UIViewController {

    // MARK: - Properties
    private let contentView = ProfileViewCell()
    private let service = ProfileService.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupLayout()
        bind()
        loadSettings()
    }

    // MARK: - Setup
    private func setupLayout() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func bind() {
        contentView.onSaveTap = { [weak self] in
            self?.saveTapped()
        }

        contentView.onAvatarTap = { [weak self] in
            self?.avatarTapped()
        }

        contentView.onChangeThemeTap = { [weak self] in
            self?.toggleTheme()
        }
    }

    // MARK: - Load
    private func loadSettings() {
        let name = service.currentUsername()
        contentView.nameLabel.text = name.isEmpty ? " " : name
        contentView.nameTextField.text = name

        if let image = service.currentAvatarImage() {
            contentView.avatarImageView.image = image
            contentView.avatarImageView.contentMode = .scaleAspectFill
            contentView.avatarImageView.tintColor = nil
        } else {
            contentView.avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            contentView.avatarImageView.tintColor = .black
            contentView.avatarImageView.contentMode = .scaleAspectFit
        }
    }

    // MARK: - Save Name
    private func saveTapped() {
        let name = contentView.nameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        service.saveUsername(name)
        contentView.nameLabel.text = name

        let alert = UIAlertController(title: nil, message: "Saved", preferredStyle: .alert)
        present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            alert.dismiss(animated: true)
        }
    }

    // MARK: - Avatar
    private func avatarTapped() {
        let alert = UIAlertController(
            title: "Change Avatar",
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentPicker()
        })

        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            self.service.saveAvatarImage(nil)
            self.loadSettings()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func presentPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Theme
    private func toggleTheme() {
        guard let window = view.window else { return }

        let isDark = window.overrideUserInterfaceStyle == .dark
        window.overrideUserInterfaceStyle = isDark ? .light : .dark
        UserDefaults.standard.set(!isDark, forKey: "isDarkMode")
    }
}

// MARK: - UIImagePicker
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)

        let image =
            (info[.editedImage] ?? info[.originalImage]) as? UIImage

        guard let img = image else { return }

        let resized = service.resizedImage(img)
        service.saveAvatarImage(resized)
        loadSettings()
    }
}
