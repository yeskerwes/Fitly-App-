//
//  HistoryCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 26.11.2025.
//

import UIKit
import SnapKit

class HistoryCell: UITableViewCell {

    static let reuseId = "HistoryCell"

    private let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.numberOfLines = 2
        return l
    }()

    private let detailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupLayout() {
        contentView.addSubview(thumbImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)

        thumbImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(56)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbImageView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().inset(16)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    func configure(with entity: ChallengeEntity) {
        titleLabel.text = entity.title ?? "Untitled"

        let state = (entity.status ?? "").capitalized
        if let date = entity.createdAt {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            detailLabel.text = "\(state) • \(df.string(from: date))"
        } else {
            detailLabel.text = state
        }

        if let imgName = entity.imageName,
           let img = UIImage(named: imgName) {
            thumbImageView.image = img
        } else {
            thumbImageView.image = UIImage(named: "bet_placeholder")
                ?? UIImage(systemName: "photo")
            thumbImageView.tintColor = .tertiaryLabel
        }
    }
}
