//
//  ModalBetViewCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 28.11.2025.
//

import UIKit

final class ModalBetViewCell: UIView {

    // MARK: - Public UI (exposed so VC can wire actions)
    let dragIndicator = UIView()
    let titleLabel = UILabel()

    let exerciseStack = UIStackView()
    public let pushButton = UIButton(type: .system)
    public let pullButton = UIButton(type: .system)

    public let quantityLabel = UILabel()
    public let durationLabel = UILabel()

    public let quantityScroll = UIScrollView()
    public let quantityStack = UIStackView()
    public private(set) var quantityButtons: [UIButton] = []

    public let durationScroll = UIScrollView()
    public let durationStack = UIStackView()
    public private(set) var durationButtons: [UIButton] = []

    public let notificationBg = UIView()
    public let notificationLabel = UILabel()
    public let notificationSwitch = UISwitch()

    public let createButton = UIButton(type: .system)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .app
        layer.cornerRadius = 40
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }

    // MARK: - Public configuration helpers

    public func configurePillButtons(quantityOptions: [Int], durationOptions: [Int], pillWidth: CGFloat = 72, pillHeight: CGFloat = 44) {
        // clear existing
        quantityButtons.forEach { $0.removeFromSuperview() }
        durationButtons.forEach { $0.removeFromSuperview() }
        quantityButtons = []
        durationButtons = []

        for val in quantityOptions {
            let b = makePillButton(title: "\(val)", width: pillWidth, height: pillHeight)
            quantityStack.addArrangedSubview(b)
            quantityButtons.append(b)
        }

        // spacer
        let qtySpacer = UIView()
        qtySpacer.translatesAutoresizingMaskIntoConstraints = false
        qtySpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        qtySpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true
        quantityStack.addArrangedSubview(qtySpacer)

        for val in durationOptions {
            let b = makePillButton(title: "\(val)", width: pillWidth, height: pillHeight)
            durationStack.addArrangedSubview(b)
            durationButtons.append(b)
        }

        let durSpacer = UIView()
        durSpacer.translatesAutoresizingMaskIntoConstraints = false
        durSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        durSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true
        durationStack.addArrangedSubview(durSpacer)
    }

    // MARK: - Private layout

    private func setupUI() {
        // Attach subviews and set styles (visuals only)
        // dragIndicator
        dragIndicator.backgroundColor = UIColor(white: 1, alpha: 0.9)
        dragIndicator.layer.cornerRadius = 3
        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        dragIndicator.layer.shadowColor = UIColor.black.cgColor
        dragIndicator.layer.shadowOpacity = 0.12
        dragIndicator.layer.shadowOffset = CGSize(width: 0, height: 2)
        dragIndicator.layer.shadowRadius = 4

        // title
        titleLabel.text = "Create the bet"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // exercise stack & buttons
        exerciseStack.axis = .horizontal
        exerciseStack.alignment = .fill
        exerciseStack.distribution = .fillEqually
        exerciseStack.spacing = 12
        exerciseStack.translatesAutoresizingMaskIntoConstraints = false

        pushButton.setTitle("Push ups", for: .normal)
        pushButton.setTitleColor(.white, for: .normal)
        pushButton.backgroundColor = UIColor(white: 1, alpha: 0.06)
        pushButton.layer.cornerRadius = 14
        pushButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        pushButton.translatesAutoresizingMaskIntoConstraints = false

        pullButton.setTitle("Pull ups", for: .normal)
        pullButton.setTitleColor(.white, for: .normal)
        pullButton.backgroundColor = UIColor(white: 1, alpha: 0.06)
        pullButton.layer.cornerRadius = 14
        pullButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        pullButton.translatesAutoresizingMaskIntoConstraints = false

        // labels
        quantityLabel.text = "Quantity per day"
        quantityLabel.textColor = .white
        quantityLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false

        durationLabel.text = "Duration (days)"
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        durationLabel.textAlignment = .right
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        // scrolls & stacks
        quantityScroll.layer.borderWidth = 2
        quantityScroll.layer.borderColor = UIColor.white.cgColor
        quantityScroll.layer.cornerRadius = 14
        quantityScroll.showsHorizontalScrollIndicator = false
        quantityScroll.translatesAutoresizingMaskIntoConstraints = false

        quantityStack.axis = .horizontal
        quantityStack.alignment = .center
        quantityStack.spacing = 10
        quantityStack.translatesAutoresizingMaskIntoConstraints = false

        durationScroll.layer.borderWidth = 2
        durationScroll.layer.borderColor = UIColor.white.cgColor
        durationScroll.layer.cornerRadius = 14
        durationScroll.showsHorizontalScrollIndicator = false
        durationScroll.translatesAutoresizingMaskIntoConstraints = false

        durationStack.axis = .horizontal
        durationStack.alignment = .center
        durationStack.spacing = 10
        durationStack.translatesAutoresizingMaskIntoConstraints = false

        // notification
        notificationBg.backgroundColor = .white
        notificationBg.layer.cornerRadius = 12
        notificationBg.layer.shadowColor = UIColor.black.cgColor
        notificationBg.layer.shadowOpacity = 0.12
        notificationBg.layer.shadowOffset = CGSize(width: 0, height: 6)
        notificationBg.layer.shadowRadius = 10
        notificationBg.translatesAutoresizingMaskIntoConstraints = false

        notificationLabel.text = "Enable Notification"
        notificationLabel.textColor = UIColor(white: 0.08, alpha: 1)
        notificationLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false

        notificationSwitch.isOn = true
        notificationSwitch.translatesAutoresizingMaskIntoConstraints = false

        // create button
        createButton.setTitle("Create the bet   ›››", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = UIColor(white: 0.06, alpha: 1)
        createButton.layer.cornerRadius = 28
        createButton.layer.shadowColor = UIColor.black.cgColor
        createButton.layer.shadowOpacity = 0.35
        createButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        createButton.layer.shadowRadius = 18
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        createButton.translatesAutoresizingMaskIntoConstraints = false

        // add subviews
        addSubview(dragIndicator)
        addSubview(titleLabel)
        addSubview(exerciseStack)
        exerciseStack.addArrangedSubview(pushButton)
        exerciseStack.addArrangedSubview(pullButton)

        addSubview(quantityLabel)
        addSubview(durationLabel)
        addSubview(quantityScroll)
        quantityScroll.addSubview(quantityStack)
        addSubview(durationScroll)
        durationScroll.addSubview(durationStack)

        addSubview(notificationBg)
        notificationBg.addSubview(notificationLabel)
        notificationBg.addSubview(notificationSwitch)

        addSubview(createButton)

        // constraints
        NSLayoutConstraint.activate([
            dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 80),
            dragIndicator.heightAnchor.constraint(equalToConstant: 6),

            titleLabel.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 34),

            exerciseStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            exerciseStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            exerciseStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            exerciseStack.heightAnchor.constraint(equalToConstant: 56),

            quantityLabel.topAnchor.constraint(equalTo: exerciseStack.bottomAnchor, constant: 18),
            quantityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            quantityLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -30),

            durationLabel.topAnchor.constraint(equalTo: exerciseStack.bottomAnchor, constant: 18),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            durationLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -30),

            quantityScroll.topAnchor.constraint(equalTo: quantityLabel.bottomAnchor, constant: 8),
            quantityScroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            quantityScroll.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -30),
            quantityScroll.heightAnchor.constraint(equalToConstant: 64),

            durationScroll.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 8),
            durationScroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            durationScroll.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -30),
            durationScroll.heightAnchor.constraint(equalToConstant: 64),

            // stack inside scroll
            quantityStack.leadingAnchor.constraint(equalTo: quantityScroll.leadingAnchor),
            quantityStack.topAnchor.constraint(equalTo: quantityScroll.topAnchor),
            quantityStack.bottomAnchor.constraint(equalTo: quantityScroll.bottomAnchor),
            quantityStack.trailingAnchor.constraint(equalTo: quantityScroll.trailingAnchor),
            quantityStack.heightAnchor.constraint(equalTo: quantityScroll.heightAnchor),

            durationStack.leadingAnchor.constraint(equalTo: durationScroll.leadingAnchor),
            durationStack.topAnchor.constraint(equalTo: durationScroll.topAnchor),
            durationStack.bottomAnchor.constraint(equalTo: durationScroll.bottomAnchor),
            durationStack.trailingAnchor.constraint(equalTo: durationScroll.trailingAnchor),
            durationStack.heightAnchor.constraint(equalTo: durationScroll.heightAnchor),

            // notification
            notificationBg.topAnchor.constraint(equalTo: quantityScroll.bottomAnchor, constant: 22),
            notificationBg.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            notificationBg.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            notificationBg.heightAnchor.constraint(equalToConstant: 64),

            notificationLabel.leadingAnchor.constraint(equalTo: notificationBg.leadingAnchor, constant: 16),
            notificationLabel.centerYAnchor.constraint(equalTo: notificationBg.centerYAnchor),
            notificationLabel.trailingAnchor.constraint(equalTo: notificationBg.trailingAnchor, constant: -110),

            notificationSwitch.trailingAnchor.constraint(equalTo: notificationBg.trailingAnchor, constant: -16),
            notificationSwitch.centerYAnchor.constraint(equalTo: notificationBg.centerYAnchor),

            // create button
            createButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -36),
            createButton.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    // convenience to create pill with fixed size
    private func makePillButton(title: String, width: CGFloat = 72, height: CGFloat = 44) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(UIColor(white: 0.85, alpha: 1), for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        b.backgroundColor = .clear
        b.layer.cornerRadius = 18
        b.translatesAutoresizingMaskIntoConstraints = false

        // ensure vertical centering
        b.contentVerticalAlignment = .center
        b.titleLabel?.textAlignment = .center

        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: width),
            b.heightAnchor.constraint(equalToConstant: height)
        ])
        return b
    }
}
