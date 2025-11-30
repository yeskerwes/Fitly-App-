//
//  ModalBetViewController.swift
//

import UIKit

// MARK: - Delegate
protocol ModalBetViewControllerDelegate: AnyObject {
    func modalBetViewController(_ controller: ModalBetViewController, didCreate entity: ChallengeEntity)
}

class ModalBetViewController: UIViewController {

    weak var delegate: ModalBetViewControllerDelegate?

    // data
    private let quantityOptions: [Int] = [10, 15, 20, 25, 30, 40, 50, 75, 100]
    private let durationOptions: [Int] = [1, 7, 14, 30, 60, 90, 100]

    private var selectedExercise: String? = nil
    private var selectedQuantityIndex: Int = 1
    private var selectedDurationIndex: Int = 0

    // UI: dim + container + the design view (ModalBetCell)
    private let dimView = UIView()
    private let containerView = UIView()
    private let designView = ModalBetViewCell()

    // bottom constraint for animation
    private var containerBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let idx = durationOptions.firstIndex(of: 30) { selectedDurationIndex = idx } else { selectedDurationIndex = 0 }

        setupBaseUI()
        wireDesignView()
        animateIn()
    }

    private func setupBaseUI() {
        view.backgroundColor = .clear

        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        dimView.addGestureRecognizer(tap)

        // container
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // initial constraint off-screen
        containerBottomConstraint = containerView.topAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.62),
            containerBottomConstraint
        ])

        // add designView into container
        containerView.addSubview(designView)
        NSLayoutConstraint.activate([
            designView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            designView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            designView.topAnchor.constraint(equalTo: containerView.topAnchor),
            designView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // gestures: pan to dismiss
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(pan)
    }

    private func wireDesignView() {
        // configure pill buttons
        designView.configurePillButtons(quantityOptions: quantityOptions, durationOptions: durationOptions)

        // wire exercise buttons
        designView.pushButton.addTarget(self, action: #selector(pushTapped), for: .touchUpInside)
        designView.pullButton.addTarget(self, action: #selector(pullTapped), for: .touchUpInside)

        // wire pill buttons: quantity
        for b in designView.quantityButtons {
            b.addTarget(self, action: #selector(quantityOptionTapped(_:)), for: .touchUpInside)
        }
        // wire pill buttons: duration
        for b in designView.durationButtons {
            b.addTarget(self, action: #selector(durationOptionTapped(_:)), for: .touchUpInside)
        }

        // wire notification & create
        designView.createButton.addTarget(self, action: #selector(handleCreateBet), for: .touchUpInside)
        // optional: use change of switch
        designView.notificationSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: .valueChanged)

        // default selection UI
        selectExercise("Push ups")
        updateQuantitySelection(animated: false)
        updateDurationSelection(animated: false)
    }

    // MARK: - Exercise actions
    @objc private func pushTapped() { selectExercise("Push ups") }
    @objc private func pullTapped() { selectExercise("Pull ups") }

    private func selectExercise(_ name: String) {
        selectedExercise = name

        let pushSelected = (name == "Push ups")
        styleExercise(button: designView.pushButton, selected: pushSelected)
        styleExercise(button: designView.pullButton, selected: !pushSelected)
    }

    private func styleExercise(button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = .white
            button.setTitleColor(UIColor(white: 0.06, alpha: 1), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.18
            button.layer.shadowOffset = CGSize(width: 0, height: 6)
            button.layer.shadowRadius = 8
        } else {
            button.backgroundColor = UIColor(white: 1, alpha: 0.06)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.layer.shadowOpacity = 0
            button.layer.shadowRadius = 0
        }
    }

    // MARK: - Options (pills)
    @objc private func quantityOptionTapped(_ sender: UIButton) {
        guard let idx = designView.quantityButtons.firstIndex(of: sender) else { return }
        selectedQuantityIndex = idx
        updateQuantitySelection(animated: true)
        scrollToButton(scroll: designView.quantityScroll, stack: designView.quantityStack, button: sender)
    }

    @objc private func durationOptionTapped(_ sender: UIButton) {
        guard let idx = designView.durationButtons.firstIndex(of: sender) else { return }
        selectedDurationIndex = idx
        updateDurationSelection(animated: true)
        scrollToButton(scroll: designView.durationScroll, stack: designView.durationStack, button: sender)
    }

    private func updateQuantitySelection(animated: Bool) {
        for (i, btn) in designView.quantityButtons.enumerated() {
            configureOption(btn, selected: i == selectedQuantityIndex, animated: animated)
        }
    }

    private func updateDurationSelection(animated: Bool) {
        for (i, btn) in designView.durationButtons.enumerated() {
            configureOption(btn, selected: i == selectedDurationIndex, animated: animated)
        }
    }

    private func configureOption(_ btn: UIButton, selected: Bool, animated: Bool) {
        let changes = {
            if selected {
                btn.backgroundColor = .white
                btn.setTitleColor(UIColor(white: 0.06, alpha: 1), for: .normal)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(UIColor(white: 0.85, alpha: 1), for: .normal)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            }
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    private func scrollToButton(scroll: UIScrollView, stack: UIStackView, button: UIView) {
        let buttonFrame = button.convert(button.bounds, to: stack)
        var targetX = buttonFrame.midX - scroll.bounds.width / 2
        targetX = max(0, min(targetX, scroll.contentSize.width - scroll.bounds.width))
        scroll.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
    }

    // MARK: - Notification
    @objc private func notificationChanged(_ s: UISwitch) {
        // VC-level reaction (if needed)
        // Example: schedule local notification toggle
        print("notifications:", s.isOn)
    }

    // MARK: - Create action
    @objc private func handleCreateBet() {
        guard let exercise = selectedExercise else {
            let ac = UIAlertController(title: "Выберите упражнение", message: "Перед созданием челленджа выберите Push ups или Pull ups.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "ОК", style: .default))
            present(ac, animated: true)
            return
        }

        let quantity = quantityOptions[selectedQuantityIndex]
        let days = durationOptions[selectedDurationIndex]

        let imageName = exercise.lowercased().contains("pull") ? "pullUp" : "pushUp"

        let entity = CoreDataManager.shared.createChallenge(
            title: "Day 01 - \(exercise)",
            imageName: imageName,
            days: days,
            quantityPerDay: quantity,
            status: "active",
            createdAt: Date()
        )

        delegate?.modalBetViewController(self, didCreate: entity)
        close()
    }

    // MARK: - Animations / pan / close

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerBottomConstraint.constant = translation.y
                view.layoutIfNeeded()
            }
        case .ended:
            if translation.y > 120 {
                close()
            } else {
                containerBottomConstraint.constant = 0
                UIView.animate(withDuration: 0.25) {
                    self.view.layoutIfNeeded()
                }
            }
        default: break
        }
    }

    @objc private func close() {
        animateOut {
            self.dismiss(animated: false)
        }
    }

    private func animateIn() {
        containerBottomConstraint.isActive = false
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint.isActive = true
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.25) { self.dimView.alpha = 1 }
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.8, options: []) {
            self.view.layoutIfNeeded()
        }
    }

    private func animateOut(_ completion: @escaping () -> Void) {
        containerBottomConstraint.isActive = false
        containerBottomConstraint = containerView.topAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint.isActive = true

        UIView.animate(withDuration: 0.22, animations: {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in completion() })
    }

    // adjust scroll sizes after layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // compute content sizes
        designView.quantityStack.layoutIfNeeded()
        var qtyWidth: CGFloat = 0
        for v in designView.quantityStack.arrangedSubviews {
            qtyWidth += v.bounds.width
            qtyWidth += designView.quantityStack.spacing
        }
        qtyWidth = max(qtyWidth, designView.quantityScroll.bounds.width)
        designView.quantityScroll.contentSize = CGSize(width: qtyWidth, height: designView.quantityScroll.bounds.height)

        designView.durationStack.layoutIfNeeded()
        var durWidth: CGFloat = 0
        for v in designView.durationStack.arrangedSubviews {
            durWidth += v.bounds.width
            durWidth += designView.durationStack.spacing
        }
        durWidth = max(durWidth, designView.durationScroll.bounds.width)
        designView.durationScroll.contentSize = CGSize(width: durWidth, height: designView.durationScroll.bounds.height)

        // ensure selected visible
        if designView.quantityButtons.indices.contains(selectedQuantityIndex) {
            scrollToButton(scroll: designView.quantityScroll, stack: designView.quantityStack, button: designView.quantityButtons[selectedQuantityIndex])
        }
        if designView.durationButtons.indices.contains(selectedDurationIndex) {
            scrollToButton(scroll: designView.durationScroll, stack: designView.durationStack, button: designView.durationButtons[selectedDurationIndex])
        }
    }
}
