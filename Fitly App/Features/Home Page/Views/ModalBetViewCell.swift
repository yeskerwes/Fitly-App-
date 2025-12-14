//
//  ModalBetViewCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 28.11.2025.
//
import UIKit
import SnapKit

final class ModalBetViewCell: UIView {

    // MARK: - Public UI
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
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        setupConstraints()
    }

    // MARK: - Public configuration

    public func configurePillButtons(
        quantityOptions: [Int],
        durationOptions: [Int],
        pillWidth: CGFloat = 72,
        pillHeight: CGFloat = 44
    ) {
        quantityButtons.forEach { $0.removeFromSuperview() }
        durationButtons.forEach { $0.removeFromSuperview() }
        quantityButtons.removeAll()
        durationButtons.removeAll()

        quantityStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        durationStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for val in quantityOptions {
            let b = makePillButton(title: "\(val)", width: pillWidth, height: pillHeight)
            quantityStack.addArrangedSubview(b)
            quantityButtons.append(b)
        }

        let qtySpacer = UIView()
        qtySpacer.snp.makeConstraints { $0.width.greaterThanOrEqualTo(8) }
        quantityStack.addArrangedSubview(qtySpacer)

        for val in durationOptions {
            let b = makePillButton(title: "\(val)", width: pillWidth, height: pillHeight)
            durationStack.addArrangedSubview(b)
            durationButtons.append(b)
        }

        let durSpacer = UIView()
        durSpacer.snp.makeConstraints { $0.width.greaterThanOrEqualTo(8) }
        durationStack.addArrangedSubview(durSpacer)
    }

    // MARK: - Setup UI

    private func setupUI() {

        dragIndicator.backgroundColor = UIColor(white: 1, alpha: 0.9)
        dragIndicator.layer.cornerRadius = 3

        titleLabel.text = "Create the bet"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .white

        exerciseStack.axis = .horizontal
        exerciseStack.spacing = 12
        exerciseStack.distribution = .fillEqually

        pushButton.setTitle("Push ups", for: .normal)
        pushButton.setTitleColor(.white, for: .normal)
        pushButton.backgroundColor = UIColor(white: 1, alpha: 0.06)
        pushButton.layer.cornerRadius = 14
        pushButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)

        pullButton.setTitle("Pull ups", for: .normal)
        pullButton.setTitleColor(.white, for: .normal)
        pullButton.backgroundColor = UIColor(white: 1, alpha: 0.06)
        pullButton.layer.cornerRadius = 14
        pullButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)

        quantityLabel.text = "Quantity per day"
        quantityLabel.textColor = .white
        quantityLabel.font = .systemFont(ofSize: 18, weight: .medium)

        durationLabel.text = "Duration (days)"
        durationLabel.textColor = .white
        durationLabel.font = .systemFont(ofSize: 18, weight: .medium)
        durationLabel.textAlignment = .right

        quantityScroll.layer.borderWidth = 2
        quantityScroll.layer.borderColor = UIColor.white.cgColor
        quantityScroll.layer.cornerRadius = 14
        quantityScroll.showsHorizontalScrollIndicator = false

        quantityStack.axis = .horizontal
        quantityStack.spacing = 10
        quantityStack.alignment = .center

        durationScroll.layer.borderWidth = 2
        durationScroll.layer.borderColor = UIColor.white.cgColor
        durationScroll.layer.cornerRadius = 14
        durationScroll.showsHorizontalScrollIndicator = false

        durationStack.axis = .horizontal
        durationStack.spacing = 10
        durationStack.alignment = .center

        notificationBg.backgroundColor = .white
        notificationBg.layer.cornerRadius = 12

        notificationLabel.text = "Enable Notification"
        notificationLabel.textColor = UIColor(white: 0.08, alpha: 1)
        notificationLabel.font = .systemFont(ofSize: 18)

        createButton.setTitle("Create the bet   ›››", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = UIColor(white: 0.06, alpha: 1)
        createButton.layer.cornerRadius = 28
        createButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)

        // hierarchy
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
    }

    // MARK: - Constraints

    private func setupConstraints() {

        dragIndicator.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(80)
            $0.height.equalTo(6)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dragIndicator.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(34)
        }

        exerciseStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(56)
        }

        quantityLabel.snp.makeConstraints {
            $0.top.equalTo(exerciseStack.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(20)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-30)
        }

        durationLabel.snp.makeConstraints {
            $0.top.equalTo(exerciseStack.snp.bottom).offset(18)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-30)
        }

        quantityScroll.snp.makeConstraints {
            $0.top.equalTo(quantityLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-30)
            $0.height.equalTo(64)
        }

        durationScroll.snp.makeConstraints {
            $0.top.equalTo(durationLabel.snp.bottom).offset(8)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-30)
            $0.height.equalTo(64)
        }

        quantityStack.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalTo(quantityScroll)
            $0.height.equalTo(quantityScroll)
        }

        durationStack.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalTo(durationScroll)
            $0.height.equalTo(durationScroll)
        }

        notificationBg.snp.makeConstraints {
            $0.top.equalTo(quantityScroll.snp.bottom).offset(22)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(64)
        }

        notificationLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(110)
        }

        notificationSwitch.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        createButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(36)
            $0.height.equalTo(64)
        }
    }

    // MARK: - Helpers

    private func makePillButton(title: String, width: CGFloat, height: CGFloat) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(UIColor(white: 0.85, alpha: 1), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        b.layer.cornerRadius = 18

        b.snp.makeConstraints {
            $0.width.equalTo(width)
            $0.height.equalTo(height)
        }

        return b
    }
}
