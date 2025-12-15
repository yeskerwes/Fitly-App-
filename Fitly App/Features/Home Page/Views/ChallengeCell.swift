import UIKit
import SnapKit

class ChallengeCell: UICollectionViewCell {
    static let reuseId = "ChallengeCell"
    
    private let contentContainer: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.layer.cornerRadius = 28
        return v
    }()

    private let bgImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.35)
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-Medium", size: 24)
        l.textColor = .white
        l.numberOfLines = 2
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-Medium", size: 18)
        l.textColor = UIColor(white: 1, alpha: 0.95)
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-Regular", size: 14)
        l.textColor = UIColor(white: 1, alpha: 0.75)
        return l
    }()

    private let leftBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 88/255, green: 92/255, blue: 246/255, alpha: 1)
        v.layer.cornerRadius = 2
        return v
    }()

    private let subtitleContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 12
        return sv
    }()

    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.titleLabel?.font = UIFont(name: "Poppins-Medium", size: 16)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.systemRed
        b.layer.cornerRadius = 28
        return b
    }()

    var onCancelTapped: (() -> Void)?

    private(set) var isOpen: Bool = false
    private var containerLeadingConstraint: Constraint!
    private var containerTrailingConstraint: Constraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        contentView.layer.cornerRadius = 28
        contentView.layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupViews() {
        contentView.addSubview(cancelButton)
        contentView.addSubview(contentContainer)

        contentContainer.addSubview(bgImageView)
        contentContainer.addSubview(overlayView)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(subtitleContainer)
        contentContainer.addSubview(dateLabel)

        subtitleContainer.addArrangedSubview(leftBar)
        subtitleContainer.addArrangedSubview(subtitleLabel)
        
        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(200)
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(110)
        }

        contentContainer.snp.makeConstraints { make in
            make.height.equalTo(200)
            containerLeadingConstraint = make.leading.equalToSuperview().offset(16).constraint
            containerTrailingConstraint = make.trailing.equalToSuperview().offset(-16).constraint
        }

        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(bgImageView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(bgImageView).offset(28)
            make.trailing.lessThanOrEqualTo(bgImageView).inset(28)
            make.bottom.equalTo(subtitleContainer.snp.top).offset(-8)
        }

        subtitleContainer.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(bgImageView).inset(28)
            make.bottom.equalTo(dateLabel.snp.top).offset(-8)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(bgImageView).inset(18)
        }

        leftBar.snp.makeConstraints { make in
            make.width.equalTo(6)
            make.height.equalTo(22)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentContainer.layer.cornerRadius = 28
        contentContainer.layer.masksToBounds = true
    }

    func configure(with entity: ChallengeEntity) {
        titleLabel.text = entity.title ?? "Untitled"
        subtitleLabel.text = "\(Int(entity.days)) days - \(Int(entity.quantityPerDay)) quantity"
        if let date = entity.createdAt {
            let df = DateFormatter()
            df.dateFormat = "d MMM yyyy 'at' HH:mm"
            dateLabel.text = df.string(from: date)
        } else {
            dateLabel.text = ""
        }

        if let imgName = entity.imageName, let img = UIImage(named: imgName) {
            bgImageView.image = img
        } else {
            bgImageView.image = UIImage(named: "bet_placeholder") ?? UIImage(systemName: "photo")
        }

        close(animated: false)
    }

    func open(animated: Bool = true) {
        guard !isOpen else { return }
        isOpen = true
        containerLeadingConstraint.update(offset: 16 - 120)
        containerTrailingConstraint.update(offset: -16 - 120)
        if animated {
            UIView.animate(withDuration: 0.25) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }

    func close(animated: Bool = true) {
        guard isOpen || containerLeadingConstraint.layoutConstraints.first?.constant != 16 else { return }
        isOpen = false
        containerLeadingConstraint.update(offset: 16)
        containerTrailingConstraint.update(offset: -16)
        if animated {
            UIView.animate(withDuration: 0.22) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }

    @objc private func cancelTapped() {
        onCancelTapped?()
    }
}
