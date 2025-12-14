import UIKit
import SnapKit

// MARK: - Delegate
protocol ModalBetViewControllerDelegate: AnyObject {
    func modalBetViewController(_ controller: ModalBetViewController, didCreate entity: ChallengeEntity)
}

final class ModalBetViewController: UIViewController {

    weak var delegate: ModalBetViewControllerDelegate?

    private let quantityOptions: [Int] = [10, 15, 20, 25, 30, 40, 50, 75, 100]
    private let durationOptions: [Int] = [1, 7, 14, 30, 60, 90, 100]

    private var selectedExercise: String?
    private var selectedQuantityIndex: Int = 1
    private var selectedDurationIndex: Int = 0

    private let dimView = UIView()
    private let containerView = UIView()
    private let designView = ModalBetViewCell()

    /// constraint для анимации
    private var containerBottomConstraint: Constraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if let idx = durationOptions.firstIndex(of: 30) {
            selectedDurationIndex = idx
        }

        setupUI()
        wireDesignView()
        animateIn()
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .clear

        // dim
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.alpha = 0
        view.addSubview(dimView)

        dimView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        dimView.addGestureRecognizer(tap)

        // container
        view.addSubview(containerView)
        containerView.backgroundColor = .clear

        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview().multipliedBy(0.62)
            containerBottomConstraint = $0.top.equalTo(view.snp.bottom).constraint
        }

        // design view
        containerView.addSubview(designView)
        designView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(pan)
    }

    // MARK: - Wiring

    private func wireDesignView() {
        designView.configurePillButtons(
            quantityOptions: quantityOptions,
            durationOptions: durationOptions
        )

        designView.pushButton.addTarget(self, action: #selector(pushTapped), for: .touchUpInside)
        designView.pullButton.addTarget(self, action: #selector(pullTapped), for: .touchUpInside)

        designView.quantityButtons.forEach {
            $0.addTarget(self, action: #selector(quantityOptionTapped(_:)), for: .touchUpInside)
        }

        designView.durationButtons.forEach {
            $0.addTarget(self, action: #selector(durationOptionTapped(_:)), for: .touchUpInside)
        }

        designView.createButton.addTarget(self, action: #selector(handleCreateBet), for: .touchUpInside)
        designView.notificationSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: .valueChanged)

        selectExercise("Push ups")
        updateQuantitySelection(animated: false)
        updateDurationSelection(animated: false)
    }

    // MARK: - Exercise

    @objc private func pushTapped() { selectExercise("Push ups") }
    @objc private func pullTapped() { selectExercise("Pull ups") }

    private func selectExercise(_ name: String) {
        selectedExercise = name
        styleExercise(button: designView.pushButton, selected: name == "Push ups")
        styleExercise(button: designView.pullButton, selected: name == "Pull ups")
    }

    private func styleExercise(button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = .white
            button.setTitleColor(UIColor(white: 0.06, alpha: 1), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.18
            button.layer.shadowOffset = CGSize(width: 0, height: 6)
            button.layer.shadowRadius = 8
        } else {
            button.backgroundColor = UIColor(white: 1, alpha: 0.06)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            button.layer.shadowOpacity = 0
        }
    }

    // MARK: - Pills

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
                btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(UIColor(white: 0.85, alpha: 1), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 16)
            }
        }

        animated
            ? UIView.animate(withDuration: 0.18, animations: changes)
            : changes()
    }

    private func scrollToButton(scroll: UIScrollView, stack: UIStackView, button: UIView) {
        let frame = button.convert(button.bounds, to: stack)
        var x = frame.midX - scroll.bounds.width / 2
        x = max(0, min(x, scroll.contentSize.width - scroll.bounds.width))
        scroll.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }

    // MARK: - Create

    @objc private func handleCreateBet() {
        guard let exercise = selectedExercise else { return }

        let quantity = quantityOptions[selectedQuantityIndex]
        let days = durationOptions[selectedDurationIndex]
        let imageName = exercise.contains("Pull") ? "pullUp" : "pushUp"

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

    // MARK: - Pan / animations

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let y = g.translation(in: view).y

        switch g.state {
        case .changed:
            if y > 0 {
                containerBottomConstraint?.update(offset: y)
                view.layoutIfNeeded()
            }
        case .ended:
            if y > 120 {
                close()
            } else {
                containerBottomConstraint?.update(offset: 0)
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
        containerBottomConstraint?.deactivate()

        containerView.snp.makeConstraints {
            containerBottomConstraint = $0.bottom.equalToSuperview().constraint
        }

        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.25) { self.dimView.alpha = 1 }
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.8,
            options: []
        ) {
            self.view.layoutIfNeeded()
        }
    }

    private func animateOut(_ completion: @escaping () -> Void) {
        containerBottomConstraint?.deactivate()

        containerView.snp.makeConstraints {
            containerBottomConstraint = $0.top.equalTo(view.snp.bottom).constraint
        }

        UIView.animate(withDuration: 0.22, animations: {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in completion() })
    }

    @objc private func notificationChanged(_ s: UISwitch) {
        print("notifications:", s.isOn)
    }
}
