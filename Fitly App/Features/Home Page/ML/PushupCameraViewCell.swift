//
//  PushupCameraViewCell.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 16.12.2025.
//

import UIKit
import SnapKit

final class PushupCameraViewCell: UIView {

    // MARK: - UI
    let previewContainer = UIView()
    let overlayView = OverlayView()

    let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-Bold" , size: 28)
        l.textColor = .white
        l.text = "Push Up"
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let bigCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-SemiBold" , size: 120)
        l.textColor = .white
        l.text = "0"
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.4
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let fractionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Poppins-SemiBold" , size: 28)
        l.textColor = UIColor(white: 1, alpha: 0.8)
        l.text = "/0"
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .left
        return l
    }()

    let endSessionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("END SESSION", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .app
        b.layer.cornerRadius = 28
        b.titleLabel?.font = UIFont(name: "Poppins-SemiBold" , size: 20)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    let cameraWarningLabel: UILabel = {
        let l = UILabel()
        l.text = "Camera can make mistakes.\nWe recommend checking the camera position."
        l.numberOfLines = 2
        l.font = UIFont(name: "Poppins-Regular" , size: 13)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI setup (КОПИЯ ИЗ VC)
    private func setupUI() {
        backgroundColor = .black
        previewContainer.clipsToBounds = true

        addSubview(previewContainer)
        previewContainer.addSubview(overlayView)

        addSubview(titleLabel)
        addSubview(bigCountLabel)
        addSubview(fractionLabel)
        addSubview(endSessionButton)
        addSubview(cameraWarningLabel)

        previewContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(10)
            $0.centerX.equalToSuperview()
        }

        bigCountLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.centerX.equalToSuperview().offset(-10)
            $0.height.equalTo(140)
            $0.width.lessThanOrEqualToSuperview().multipliedBy(0.8)
        }

        fractionLabel.snp.makeConstraints {
            $0.leading.equalTo(bigCountLabel.snp.trailing).offset(6)
            $0.bottom.equalTo(bigCountLabel.snp.bottom).offset(-28)
        }

        endSessionButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-40)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(64)
            $0.width.equalToSuperview().multipliedBy(0.6)
        }

        cameraWarningLabel.snp.makeConstraints {
            $0.bottom.equalTo(endSessionButton.snp.top).offset(-12)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.9)
        }
    }
}
