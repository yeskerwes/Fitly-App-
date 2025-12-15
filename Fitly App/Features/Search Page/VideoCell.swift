//
//  VideoCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 12.12.2025.
//


import UIKit

final class VideoCell: UITableViewCell {
    static let reuseId = "VideoCell"

    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var currentTask: Task<Void, Never>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumb.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        currentTask?.cancel()
    }

    private func setup() {
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 6
        contentView.addSubview(thumb)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "Poppins-SemiBold" , size: 16)
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont(name: "Poppins-Medium" , size: 12)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 120),
            thumb.heightAnchor.constraint(equalToConstant: 68),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with item: VideoItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.description

        currentTask = Task { [weak self] in
            if let url = item.thumbnailURL {
                do {
                    let img = try await ImageLoader.shared.load(url)
                    guard !Task.isCancelled else { return }
                    DispatchQueue.main.async {
                        self?.thumb.image = img
                    }
                } catch {
                }
            } else {
                DispatchQueue.main.async { self?.thumb.image = nil }
            }
        }
    }
}

