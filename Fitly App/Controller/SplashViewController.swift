//
//  SplashViewController.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 16.12.2025.
//

import UIKit
import SnapKit

final class SplashViewController: UIViewController {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "FitlyIcon"))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        imageView.alpha = 0
        imageView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.15
        imageView.layer.shadowRadius = 20
        imageView.layer.shadowOffset = CGSize(width: 0, height: 8)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Fitly App"
        label.font = UIFont(name: "Poppins-Bold", size: 32)
        label.textColor = .white
        label.alpha = 0
        label.transform = CGAffineTransform(translationX: 8, y: 0)
        return label
    }()

    private var iconCenterXConstraint: Constraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .app
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIconIn()
    }

    private func setupUI() {
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            self.iconCenterXConstraint = make.centerX.equalToSuperview().constraint
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(14)
        }
    }

    private func animateIconIn() {
        UIView.animate(
            withDuration: 0.9,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.iconImageView.alpha = 1
            self.iconImageView.transform = .identity
        } completion: { _ in
            self.animateIconShift()
        }
    }

    private func animateIconShift() {
        iconCenterXConstraint?.update(offset: -74)

        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.animateTitleIn()
        }
    }

    private func animateTitleIn() {
        UIView.animate(
            withDuration: 0.45,
            delay: 0.05,
            options: [.curveEaseOut]
        ) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.showMain()
            }
        }
    }

    private func showMain() {
        let tabBar = MainTabBarController()
        let nav = UINavigationController(rootViewController: tabBar)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }
}
