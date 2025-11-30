//
//  ChallengeDetailViewCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 30.11.2025.
//

import UIKit

final class ChallengeDetailViewCell: UIView {

    // MARK: - Callbacks
    /// Called when user taps Start button
    var onStartTapped: (() -> Void)?
    /// Called when user taps Back (if used)
    var onBackTapped: (() -> Void)?

    // MARK: - Font helper (Poppins with fallback)
    private func poppinsFont(_ style: String, size: CGFloat) -> UIFont {
        if let f = UIFont(name: style, size: size) { return f }
        switch style.lowercased() {
        case let s where s.contains("bold") || s.contains("black"):
            return UIFont.systemFont(ofSize: size, weight: .bold)
        case let s where s.contains("semibold") || s.contains("medium"):
            return UIFont.systemFont(ofSize: size, weight: .semibold)
        case let s where s.contains("light"):
            return UIFont.systemFont(ofSize: size, weight: .light)
        default:
            return UIFont.systemFont(ofSize: size, weight: .regular)
        }
    }

    // MARK: - Views (public for controller to change if needed)
    let scrollView = UIScrollView()
    let content = UIView()

    private(set) var headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let headerOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.18)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private(set) var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-Bold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 2
        return l
    }()

    private(set) var feeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-SemiBold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metricsContainer: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private(set) var doneTodayLabel: UILabel = {
        let l = UILabel()
        l.text = "DONE TODAY"
        l.font = UIFont(name: "Poppins-SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .darkGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private(set) var doneTodayValueLabel: UILabel = {
        let l = UILabel()
        l.text = "0 / 0"
        l.font = UIFont(name: "Poppins-SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .darkGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let doneProgress = MiniProgressView()

    private(set) var completedLabel: UILabel = {
        let l = UILabel()
        l.text = "COMPLETED DAYS"
        l.font = UIFont(name: "Poppins-SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .darkGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let completedPillsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private(set) var startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Start", for: .normal)
        if let font = UIFont(name: "Poppins-SemiBold", size: 20) {
            b.titleLabel?.font = font
        } else {
            b.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        }
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 28
        b.backgroundColor = .app
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.masksToBounds = true
        return b
    }()

    private(set) var backButton: UIButton = {
        let b = UIButton(type: .system)
        let conf = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: conf), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(white: 1, alpha: 0.15)
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
        setupActions()
    }

    // MARK: - Setup
    private func setupHierarchy() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(content)

        content.addSubview(headerImageView)
        headerImageView.addSubview(headerOverlay)
        headerImageView.addSubview(backButton)
        headerImageView.addSubview(titleLabel)
        headerImageView.addSubview(feeLabel)

        content.addSubview(metricsContainer)
        metricsContainer.addArrangedSubview(metricCard(iconName: "target", title: "", subtitle: "Daily Target"))
        metricsContainer.addArrangedSubview(metricCard(iconName: "calendar", title: "", subtitle: "Duration"))

        content.addSubview(doneTodayLabel)
        content.addSubview(doneTodayValueLabel)
        content.addSubview(doneProgress)

        content.addSubview(completedLabel)
        content.addSubview(completedPillsStack)

        content.addSubview(startButton)
    }

    private func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        let safe = safeAreaLayoutGuide
        let headerHeight: CGFloat = 240

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerImageView.topAnchor.constraint(equalTo: content.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: headerHeight),

            headerOverlay.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            headerOverlay.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            headerOverlay.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            headerOverlay.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),

            backButton.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: headerImageView.topAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: headerImageView.centerYAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerImageView.trailingAnchor, constant: -16),

            feeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            feeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            metricsContainer.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 18),
            metricsContainer.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            metricsContainer.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            metricsContainer.heightAnchor.constraint(equalToConstant: 110),

            doneTodayLabel.topAnchor.constraint(equalTo: metricsContainer.bottomAnchor, constant: 22),
            doneTodayLabel.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),

            doneTodayValueLabel.centerYAnchor.constraint(equalTo: doneTodayLabel.centerYAnchor),
            doneTodayValueLabel.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),

            doneProgress.topAnchor.constraint(equalTo: doneTodayLabel.bottomAnchor, constant: 10),
            doneProgress.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            doneProgress.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            doneProgress.heightAnchor.constraint(equalToConstant: 10),

            completedLabel.topAnchor.constraint(equalTo: doneProgress.bottomAnchor, constant: 18),
            completedLabel.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),

            completedPillsStack.topAnchor.constraint(equalTo: completedLabel.bottomAnchor, constant: 10),
            completedPillsStack.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            completedPillsStack.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            completedPillsStack.heightAnchor.constraint(equalToConstant: 16),

            startButton.topAnchor.constraint(equalTo: completedPillsStack.bottomAnchor, constant: 28),
            startButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            startButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            startButton.heightAnchor.constraint(equalToConstant: 64),
            startButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24)
        ])
    }

    private func setupActions() {
        startButton.addTarget(self, action: #selector(handleStart), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }

    // MARK: - Public update API
    /// Update UI with provided values. Controller should call this after fetching Core Data values.
    func updateUI(exerciseName: String,
                  imageName: String?,
                  quantityPerDay: Int,
                  daysTotal: Int,
                  doneToday: Int,
                  completedDays: Int,
                  accentColor: UIColor = .app) {

        titleLabel.text = exerciseName
        if let img = imageName.flatMap({ UIImage(named: $0) }) {
            headerImageView.image = img
        }

        // metric cards titles
        if let dailyCard = metricsContainer.arrangedSubviews.first,
           let titleLbl = dailyCard.subviews.compactMap({ $0 as? UILabel }).first {
            titleLbl.text = "\(quantityPerDay) reps/day"
            titleLbl.font = poppinsFont("Poppins-SemiBold", size: 18)
        }
        if let durCard = metricsContainer.arrangedSubviews.last,
           let titleLbl = durCard.subviews.compactMap({ $0 as? UILabel }).first {
            titleLbl.text = "\(daysTotal) days"
            titleLbl.font = poppinsFont("Poppins-SemiBold", size: 18)
        }

        doneTodayValueLabel.text = "\(doneToday) / \(quantityPerDay)"
        doneProgress.setAccentColor(accentColor)
        let progress: CGFloat = quantityPerDay > 0 ? CGFloat(min(doneToday, quantityPerDay)) / CGFloat(quantityPerDay) : 0
        doneProgress.setProgress(progress, animated: true)

        // pills
        completedPillsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxPills = min(max(daysTotal, 0), 120)
        for i in 0..<maxPills {
            let pill = UIView()
            pill.layer.cornerRadius = 8
            pill.layer.borderWidth = 1
            pill.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
            pill.translatesAutoresizingMaskIntoConstraints = false
            pill.backgroundColor = i < completedDays ? accentColor : .white
            completedPillsStack.addArrangedSubview(pill)
            pill.heightAnchor.constraint(equalToConstant: 14).isActive = true
        }

        // style metric icon backgrounds
        if let firstIconBg = (metricsContainer.arrangedSubviews.first?.subviews.compactMap { $0 as? UIView }.first) {
            firstIconBg.backgroundColor = accentColor
        }
    }

    // MARK: - Private helpers
    @objc private func handleStart() {
        onStartTapped?()
    }

    @objc private func handleBack() {
        onBackTapped?()
    }

    private func metricCard(iconName: String, title: String, subtitle: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconBg = UIView()
        iconBg.layer.cornerRadius = 28
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = poppinsFont("Poppins-SemiBold", size: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = poppinsFont("Poppins-Regular", size: 13)
        subtitleLabel.textColor = UIColor.darkGray.withAlphaComponent(0.9)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconBg)
        iconBg.addSubview(icon)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconBg.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 56),
            iconBg.heightAnchor.constraint(equalToConstant: 56),

            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 26),
            icon.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: iconBg.topAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: -2),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])

        iconBg.backgroundColor = .app
        return card
    }
}

// MARK: - MiniProgressView (internal to UI file)
private final class MiniProgressView: UIView {
    private let bg = UIView()
    private let fg = UIView()
    private var fgWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.backgroundColor = UIColor(white: 0.9, alpha: 1)
        bg.layer.cornerRadius = 5
        addSubview(bg)

        fg.translatesAutoresizingMaskIntoConstraints = false
        fg.layer.cornerRadius = 5
        bg.addSubview(fg)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),

            fg.topAnchor.constraint(equalTo: bg.topAnchor),
            fg.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            fg.bottomAnchor.constraint(equalTo: bg.bottomAnchor),
        ])
        fgWidthConstraint = fg.widthAnchor.constraint(equalToConstant: 0)
        fgWidthConstraint?.isActive = true
    }

    func setAccentColor(_ color: UIColor) {
        fg.backgroundColor = color
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        let p = max(0, min(1, progress))
        let full = bg.bounds.width
        let newWidth = max(6, full * p)
        fgWidthConstraint?.constant = newWidth
        if animated {
            UIView.animate(withDuration: 0.35) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if fgWidthConstraint?.constant == 0 {
            fgWidthConstraint?.constant = 0
        }
    }
}
