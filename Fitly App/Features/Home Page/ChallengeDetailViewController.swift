import UIKit
import CoreData

final class ChallengeDetailViewController: UIViewController {

    // MARK: - Data
    private let entity: ChallengeEntity

    // UI (the whole screen is inside this UIView)
    private lazy var detailView: ChallengeDetailViewCell = {
        let v = ChallengeDetailViewCell()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init
    init(entity: ChallengeEntity) {
        self.entity = entity
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindCallbacks()
        configureFromEntity()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // nothing else needed; UI handles its own gradients if any
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(detailView)
        NSLayoutConstraint.activate([
            detailView.topAnchor.constraint(equalTo: view.topAnchor),
            detailView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bindCallbacks() {
        detailView.onStartTapped = { [weak self] in
            self?.startAction()
        }
        detailView.onBackTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Configure from Core Data entity
    private func configureFromEntity() {
        // safe reads for possible Int/Int16 types
        let quantityPerDay = Int(entity.quantityPerDay)
        let daysTotal = Int(entity.days)

        let doneToday = intValueSafely(forKey: "doneToday", in: entity) ?? 0
        let completedDays = intValueSafely(forKey: "completedDays", in: entity) ?? 0

        let imageName = (entity.imageName?.isEmpty == false) ? entity.imageName : nil
        let title = entity.title ?? "Challenge"

        detailView.updateUI(exerciseName: title,
                            imageName: imageName,
                            quantityPerDay: quantityPerDay,
                            daysTotal: daysTotal,
                            doneToday: doneToday,
                            completedDays: completedDays,
                            accentColor: .app)
    }

    // MARK: - Start flow (logic)
    private func startAction() {
        // Present camera VC to count reps using Vision body pose
        let cam = PushupCameraViewController()
        cam.modalPresentationStyle = .fullScreen
        cam.delegate = self
        present(cam, animated: true, completion: nil)
    }

    // MARK: - Core Data helpers (reads/writes)
    private func intValueSafely(forKey key: String, in entity: NSManagedObject) -> Int? {
        guard entity.entity.propertiesByName.keys.contains(key) else { return nil }
        if let v = entity.value(forKey: key) as? Int { return v }
        if let v = entity.value(forKey: key) as? Int16 { return Int(v) }
        if let v = entity.value(forKey: key) as? Int32 { return Int(v) }
        if let v = entity.value(forKey: key) as? NSNumber { return v.intValue }
        return nil
    }

    private func setIntValue(_ value: Int, forKey key: String, on entity: NSManagedObject) {
        if let attr = entity.entity.attributesByName[key], attr.attributeType == .integer16AttributeType {
            entity.setValue(Int16(value), forKey: key)
        } else if let attr = entity.entity.attributesByName[key], attr.attributeType == .integer32AttributeType {
            entity.setValue(Int32(value), forKey: key)
        } else {
            entity.setValue(value, forKey: key)
        }
    }

    private func incrementDoneToday(by amount: Int = 1) {
        let cur = intValueSafely(forKey: "doneToday", in: entity) ?? 0
        let newVal = max(0, cur + amount)
        setIntValue(newVal, forKey: "doneToday", on: entity)
        saveAndRefreshUI()
    }

    private func markTodayCompleted() {
        let curCompleted = intValueSafely(forKey: "completedDays", in: entity) ?? 0
        setIntValue(curCompleted + 1, forKey: "completedDays", on: entity)
        setIntValue(0, forKey: "doneToday", on: entity)
        saveAndRefreshUI()
    }

    private func saveAndRefreshUI() {
        let ctx = CoreDataManager.shared.persistentContainer.viewContext
        do {
            if ctx.hasChanges { try ctx.save() }
        } catch {
            print("Failed to save ChallengeEntity changes:", error)
        }
        // update UI
        configureFromEntity()
        // notify listeners if needed
        NotificationCenter.default.post(name: .challengeStatusChanged, object: nil, userInfo: ["id": entity.value(forKey: "id") as Any, "status": "updated"])
    }
}

// MARK: - PushupCameraDelegate
extension ChallengeDetailViewController: PushupCameraDelegate {
    func pushupSessionDidFinish(count: Int) {
        guard count > 0 else {
            // nothing to save; you might show a message if you want
            return
        }

        // add counted reps to doneToday
        incrementDoneToday(by: count)

        // If reached or exceeded daily target -> mark day completed
        let quantityPerDay = Int(entity.quantityPerDay)
        let newDone = intValueSafely(forKey: "doneToday", in: entity) ?? 0
        if quantityPerDay > 0 && newDone >= quantityPerDay {
            markTodayCompleted()
        }

        // Optionally: save a WorkoutSession entity or other analytics here
    }

    func pushupSessionDidCancel() {
        // user cancelled or camera failed — nothing to do
    }
}
