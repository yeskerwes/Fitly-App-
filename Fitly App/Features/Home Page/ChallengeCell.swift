import UIKit

class ChallengeCell: UICollectionViewCell {
    static let reuseId = "ChallengeCell"

    // container that will slide left to reveal the cancel button
    private let contentContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        v.layer.cornerRadius = 28
        return v
    }()

    // background image inside container
    private let bgImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.35)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(white: 1, alpha: 0.95)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = UIColor(white: 1, alpha: 0.75)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let leftBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 88/255, green: 92/255, blue: 246/255, alpha: 1)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let subtitleContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Cancel button (sits behind the contentContainer, visible after sliding)
    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.systemRed
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // public callback
    var onCancelTapped: (() -> Void)?

    // state
    private(set) var isOpen: Bool = false
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        // ensure background and shadow
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

        // constraints
        NSLayoutConstraint.activate([
            // cancel button is anchored to the right side of the cell's contentView
            cancelButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),

            // content container (we'll slide this left)
            contentContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // leading/trailing constraints stored to manipulate transform via constraints
        containerLeadingConstraint = contentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        containerTrailingConstraint = contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        NSLayoutConstraint.activate([containerLeadingConstraint, containerTrailingConstraint])

        // bgImageView inside container
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: bgImageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: bgImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: bgImageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bgImageView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: bgImageView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: bgImageView.trailingAnchor, constant: -28),
            // subtitle above date
            subtitleContainer.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleContainer.trailingAnchor.constraint(lessThanOrEqualTo: bgImageView.trailingAnchor, constant: -28),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            // vertical layout
            titleLabel.bottomAnchor.constraint(equalTo: subtitleContainer.topAnchor, constant: -8),
            subtitleContainer.bottomAnchor.constraint(equalTo: dateLabel.topAnchor, constant: -8),
            dateLabel.bottomAnchor.constraint(equalTo: bgImageView.bottomAnchor, constant: -18),

            leftBar.widthAnchor.constraint(equalToConstant: 6),
            leftBar.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // keep corner clipping for container
        contentContainer.layer.cornerRadius = 28
        contentContainer.layer.masksToBounds = true
    }

    // configure cell with entity
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

        // ensure closed by default (reset for reused cells)
        close(animated: false)
    }

    // MARK: - open/close controls (animated)
    func open(animated: Bool = true) {
        guard !isOpen else { return }
        isOpen = true
        // slide container to left so cancel button is visible
        containerLeadingConstraint.constant = 16 - 120 // expose 120 width cancel button
        containerTrailingConstraint.constant = -16 - 120
        if animated {
            UIView.animate(withDuration: 0.25) { self.layoutIfNeeded() }
        } else { self.layoutIfNeeded() }
    }

    func close(animated: Bool = true) {
        guard isOpen || containerLeadingConstraint.constant != 16 else { return }
        isOpen = false
        containerLeadingConstraint.constant = 16
        containerTrailingConstraint.constant = -16
        if animated {
            UIView.animate(withDuration: 0.22) { self.layoutIfNeeded() }
        } else { self.layoutIfNeeded() }
    }

    @objc private func cancelTapped() {
        onCancelTapped?()
    }
}
