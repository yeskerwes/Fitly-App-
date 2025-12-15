//
//  ProfileViewCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 14.12.2025.
//

import UIKit
import SnapKit

final class ProfileViewCell: UIView {

    // MARK: - Header
    let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .app
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    // MARK: - Avatar
    let avatarContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.crop.circle.fill")
        iv.tintColor = .black
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .white
        iv.layer.borderWidth = 6
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
    }()

    let cameraBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.18, green: 0.78, blue: 0.48, alpha: 1)
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 3
        v.layer.borderColor = UIColor.white.cgColor
        return v
    }()

    let cameraIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "camera.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Name
    let nameLabel: UILabel = {
        let l = UILabel()
        l.text = "Name"
        l.font = UIFont(name: "Poppins-Bold", size: 32)
        l.textAlignment = .center
        return l
    }()

    let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter name"
        tf.font = UIFont(name: "Poppins-Regular", size: 16)
        return tf
    }()

    let nameUnderline: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray4
        return v
    }()

    let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16)
        return b
    }()

    // MARK: - Scroll
    let scrollView = UIScrollView()
    let contentView = UIView()

    let sectionProfileTitle = UILabel()
    let sectionAppearanceTitle = UILabel()
    let changeThemeLabel = UILabel()
    let sectionNotificationsTitle = UILabel()
    let notificationsLabel = UILabel()
    let notificationsSwitch = UISwitch()
    let resetButton = UIButton(type: .system)
    let bottomSpacer = UIView()

    // MARK: - Callbacks
    var onAvatarTap: (() -> Void)?
    var onSaveTap: (() -> Void)?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupTexts()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    // MARK: - Setup
    private func setupTexts() {
        sectionProfileTitle.text = "Profile"
        sectionProfileTitle.font = UIFont(name: "Poppins-SemiBold", size: 18)
        sectionProfileTitle.textColor = .systemGray

        sectionAppearanceTitle.text = "Appearance"
        sectionAppearanceTitle.font = UIFont(name: "Poppins-SemiBold", size: 18)
        sectionAppearanceTitle.textColor = .systemGray

        changeThemeLabel.text = "Change Theme"
        changeThemeLabel.font = UIFont(name: "Poppins-Medium", size: 16)

        sectionNotificationsTitle.text = "Notifications"
        sectionNotificationsTitle.font = UIFont(name: "Poppins-SemiBold", size: 18)
        sectionNotificationsTitle.textColor = .systemGray

        notificationsLabel.text = "Enable Notifications"
        notificationsLabel.font = UIFont(name: "Poppins-Medium", size: 16)

        notificationsSwitch.isOn = true
        notificationsSwitch.onTintColor = UIColor(red: 0.18, green: 0.78, blue: 0.48, alpha: 1)

        resetButton.setTitle("Reset Settings", for: .normal)
        resetButton.setTitleColor(.systemRed, for: .normal)
        resetButton.titleLabel?.font = UIFont(name: "Poppins-Medium", size: 16)
    }

    private func setupConstraints() {
        addSubview(headerImageView)
        addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(cameraBadge)
        cameraBadge.addSubview(cameraIcon)
        addSubview(nameLabel)
        addSubview(scrollView)
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

        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

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
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        )

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    @objc private func avatarTapped() {
        onAvatarTap?()
    }

    @objc private func saveTapped() {
        onSaveTap?()
    }
}
