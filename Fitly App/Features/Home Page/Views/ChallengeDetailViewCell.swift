import UIKit
import SnapKit

final class ChallengeDetailViewCell: UIView {

    var onStartTapped: (() -> Void)?
    var onBackTapped: (() -> Void)?

    let scrollView = UIScrollView()
    let content = UIView()

    private(set) var headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let headerOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.18)
        return v
    }()

    private(set) var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-Bold", size: 30)
        l.textColor = .white
        l.numberOfLines = 2
        return l
    }()

    private(set) var feeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-SemiBold", size: 16)
        l.textColor = .white
        return l
    }()

    private let metricsContainer: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    private(set) var doneTodayLabel: UILabel = {
        let l = UILabel()
        l.text = "DONE TODAY"
        l.font = UIFont(name: "Poppins-SemiBold", size: 13)
        l.textColor = .darkGray
        return l
    }()

    private(set) var doneTodayValueLabel: UILabel = {
        let l = UILabel()
        l.text = "0 / 0"
        l.font = UIFont(name: "Poppins-SemiBold", size: 13)
        l.textColor = .darkGray
        return l
    }()

    private let doneProgress = MiniProgressView()

    private(set) var completedLabel: UILabel = {
        let l = UILabel()
        l.text = "COMPLETED DAYS"
        l.font = UIFont(name: "Poppins-SemiBold", size: 13)
        l.textColor = .darkGray
        return l
    }()

    private let completedPillsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        return s
    }()

    private(set) var startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Start", for: .normal)
        b.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 20)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 28
        b.backgroundColor = .app
        b.layer.masksToBounds = true
        return b
    }()

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

    private func setupHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(content)

        content.addSubview(headerImageView)
        headerImageView.addSubview(headerOverlay)
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
        let headerHeight: CGFloat = 240
        let safe = safeAreaLayoutGuide

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safe.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }

        headerImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerHeight)
        }

        headerOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.bottom.equalTo(headerImageView.snp.centerY).offset(20)
        }

        feeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        metricsContainer.snp.makeConstraints { make in
            make.top.equalTo(headerImageView.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(110)
        }

        doneTodayLabel.snp.makeConstraints { make in
            make.top.equalTo(metricsContainer.snp.bottom).offset(22)
            make.leading.equalTo(metricsContainer.snp.leading)
        }

        doneTodayValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(doneTodayLabel)
            make.trailing.equalTo(metricsContainer.snp.trailing)
        }

        doneProgress.snp.makeConstraints { make in
            make.top.equalTo(doneTodayLabel.snp.bottom).offset(10)
            make.leading.equalTo(metricsContainer.snp.leading)
            make.trailing.equalTo(metricsContainer.snp.trailing)
            make.height.equalTo(10)
        }

        completedLabel.snp.makeConstraints { make in
            make.top.equalTo(doneProgress.snp.bottom).offset(18)
            make.leading.equalTo(metricsContainer.snp.leading)
        }

        completedPillsStack.snp.makeConstraints { make in
            make.top.equalTo(completedLabel.snp.bottom).offset(10)
            make.leading.equalTo(metricsContainer.snp.leading)
            make.trailing.equalTo(metricsContainer.snp.trailing)
            make.height.equalTo(16)
        }

        startButton.snp.makeConstraints { make in
            make.top.equalTo(completedPillsStack.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(64)
            make.bottom.equalToSuperview().inset(24)
        }
    }

    private func setupActions() {
        startButton.addTarget(self, action: #selector(handleStart), for: .touchUpInside)
    }

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

        if let dailyCard = metricsContainer.arrangedSubviews.first,
           let titleLbl = dailyCard.subviews.compactMap({ $0 as? UILabel }).first {
            titleLbl.text = "\(quantityPerDay) reps/day"
            titleLbl.font = UIFont(name: "Poppins-SemiBold", size: 18)
        }
        if let durCard = metricsContainer.arrangedSubviews.last,
           let titleLbl = durCard.subviews.compactMap({ $0 as? UILabel }).first {
            titleLbl.text = "\(daysTotal) days"
            titleLbl.font = UIFont(name: "Poppins-SemiBold", size: 18)
        }

        doneTodayValueLabel.text = "\(doneToday) / \(quantityPerDay)"
        doneProgress.setAccentColor(accentColor)
        let progress: CGFloat = quantityPerDay > 0 ? CGFloat(min(doneToday, quantityPerDay)) / CGFloat(quantityPerDay) : 0
        doneProgress.setProgress(progress, animated: true)

        completedPillsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxPills = min(max(daysTotal, 0), 120)
        for i in 0..<maxPills {
            let pill = UIView()
            pill.layer.cornerRadius = 8
            pill.layer.borderWidth = 1
            pill.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
            pill.backgroundColor = i < completedDays ? accentColor : .white
            completedPillsStack.addArrangedSubview(pill)
            pill.snp.makeConstraints { make in
                make.height.equalTo(14)
            }
        }

        if let firstIconBg = (metricsContainer.arrangedSubviews.first?.subviews.compactMap { $0 as? UIView }.first) {
            firstIconBg.backgroundColor = accentColor
        }

        if quantityPerDay > 0 && doneToday >= quantityPerDay {
            startButton.setTitle("You've completed today", for: .normal)
            startButton.backgroundColor = UIColor.systemGray
            startButton.isEnabled = false
        } else {
            startButton.setTitle("Start", for: .normal)
            startButton.backgroundColor = .app
            startButton.isEnabled = true
        }
    }

    @objc private func handleStart() {
        onStartTapped?()
    }

    @objc private func handleBack() {
        onBackTapped?()
    }

    private func metricCard(iconName: String, title: String, subtitle: String) -> UIView {
        let card = UIView()

        let iconBg = UIView()
        iconBg.layer.cornerRadius = 28

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .white
        icon.contentMode = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Poppins-SemiBold", size: 18)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont(name: "Poppins-Regular", size: 13)
        subtitleLabel.textColor = UIColor.darkGray.withAlphaComponent(0.9)

        card.addSubview(iconBg)
        iconBg.addSubview(icon)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        iconBg.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }

        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(26)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBg.snp.trailing).offset(12)
            make.top.equalTo(iconBg.snp.top).offset(6)
            make.trailing.equalToSuperview().inset(12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(iconBg.snp.bottom).offset(-2)
            make.trailing.equalToSuperview().inset(12)
        }

        iconBg.backgroundColor = .app
        return card
    }
}

private final class MiniProgressView: UIView {
    private let bg = UIView()
    private let fg = UIView()
    private var fgWidthConstraint: Constraint?
    private var currentProgress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        bg.backgroundColor = UIColor(white: 0.9, alpha: 1)
        bg.layer.cornerRadius = 5
        addSubview(bg)
        bg.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bg.addSubview(fg)
        fg.layer.cornerRadius = 5
        fg.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            fgWidthConstraint = make.width.equalTo(0).constraint
        }
    }

    func setAccentColor(_ color: UIColor) {
        fg.backgroundColor = color
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        let clamped = max(0, min(1, progress))
        currentProgress = clamped
        let targetWidth = bounds.width * clamped
        fgWidthConstraint?.update(offset: targetWidth)
        if animated {
            UIView.animate(withDuration: 0.22) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let targetWidth = bounds.width * currentProgress
        fgWidthConstraint?.update(offset: targetWidth)
    }
}
