// CoreDataManager.swift
import Foundation
import CoreData
import UIKit

final class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}

    private let modelName = "Fitly" // можно оставить как есть

    // Программно создаём NSManagedObjectModel с сущностями ChallengeEntity и Settings.
    private lazy var programmaticModel: NSManagedObjectModel = {
        // 1) attribute factories
        func stringAttribute(_ name: String, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .stringAttributeType
            a.isOptional = optional
            return a
        }

        func uuidAttribute(_ name: String, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .UUIDAttributeType
            a.isOptional = optional
            return a
        }

        func int16Attribute(_ name: String, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .integer16AttributeType
            a.isOptional = optional
            return a
        }

        func dateAttribute(_ name: String, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .dateAttributeType
            a.isOptional = optional
            return a
        }

        func binaryAttribute(_ name: String, optional: Bool = true, allowsExternalStorage: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .binaryDataAttributeType
            a.isOptional = optional
            a.allowsExternalBinaryDataStorage = allowsExternalStorage
            return a
        }

        // 2) ChallengeEntity (как было)
        let challengeEntity = NSEntityDescription()
        challengeEntity.name = "ChallengeEntity"
        // ожидание, что у тебя есть класс ChallengeEntity в проекте — оставим, как было
        challengeEntity.managedObjectClassName = NSStringFromClass(ChallengeEntity.self)
        challengeEntity.properties = [
            uuidAttribute("id", optional: true),
            stringAttribute("title", optional: true),
            stringAttribute("imageName", optional: true),
            int16Attribute("days", optional: false),
            int16Attribute("quantityPerDay", optional: false),
            dateAttribute("createdAt", optional: true),
            stringAttribute("status", optional: true)
        ]

        // 3) Settings entity (singleton row) - используем NSManagedObject (без отдельного класса)
        let settingsEntity = NSEntityDescription()
        settingsEntity.name = "Settings"
        // чтобы не требовать кастомного класса, используем NSManagedObject динамически:
        settingsEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        settingsEntity.properties = [
            stringAttribute("username", optional: true),
            binaryAttribute("avatarData", optional: true) // Binary Data для аватарки
        ]

        let model = NSManagedObjectModel()
        model.entities = [challengeEntity, settingsEntity]
        return model
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        // инициализируем контейнер с нашей программной моделью
        let container = NSPersistentContainer(name: modelName, managedObjectModel: programmaticModel)

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
            // debug output
            let names = container.managedObjectModel.entities.map { $0.name ?? "<unnamed>" }
            print("CoreData (programmatic) model entities:", names)
        }
        return container
    }()

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    func saveContext() {
        let ctx = context
        guard ctx.hasChanges else { return }
        do { try ctx.save() }
        catch { print("CoreData save error:", error) }
    }

    // =========================
    // Challenge helpers (как было)
    // =========================

    @discardableResult
    func createChallenge(title: String,
                         imageName: String,
                         days: Int,
                         quantityPerDay: Int,
                         status: String = "active",
                         createdAt: Date = Date()) -> ChallengeEntity {

        let ctx = context

        guard let entityDesc = NSEntityDescription.entity(forEntityName: "ChallengeEntity", in: ctx) else {
            let available = ctx.persistentStoreCoordinator?.managedObjectModel.entities.compactMap { $0.name } ?? []
            fatalError("NSEntityDescription not found for 'ChallengeEntity'. Available: \(available)")
        }

        let e = ChallengeEntity(entity: entityDesc, insertInto: ctx)
        e.id = UUID()
        e.title = title
        e.imageName = imageName
        e.days = Int16(days)
        e.quantityPerDay = Int16(quantityPerDay)
        e.status = status
        e.createdAt = createdAt

        saveContext()
        return e
    }

    func fetchChallenges(status: String? = nil, sortedByDateDescending: Bool = true) -> [ChallengeEntity] {
        let req: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        if let s = status {
            req.predicate = NSPredicate(format: "status == %@", s)
        }
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: !sortedByDateDescending)]
        do { return try context.fetch(req) }
        catch { print("Fetch error:", error); return [] }
    }

    func updateStatus(for entity: ChallengeEntity, to newStatus: String) {
        entity.status = newStatus
        saveContext()
    }

    func delete(_ entity: ChallengeEntity) {
        context.delete(entity)
        saveContext()
    }

    // =========================
    // Settings helpers (новые)
    // =========================

    /// Возвращает единственную запись Settings или создаёт её.
    private func fetchOrCreateSettingsObject() -> NSManagedObject {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Settings")
        req.fetchLimit = 1
        do {
            let arr = try context.fetch(req)
            if let existing = arr.first { return existing }
        } catch {
            print("Fetch settings error:", error)
        }

        guard let entityDesc = NSEntityDescription.entity(forEntityName: "Settings", in: context) else {
            fatalError("Settings entity not found in model")
        }
        let s = NSManagedObject(entity: entityDesc, insertInto: context)
        s.setValue("", forKey: "username")
        s.setValue(nil, forKey: "avatarData")
        saveContext()
        return s
    }

    /// Текущий username (String)
    func currentUsername() -> String {
        let s = fetchOrCreateSettingsObject()
        return (s.value(forKey: "username") as? String) ?? ""
    }

    /// Текущий аватар как UIImage?
    func currentAvatarImage() -> UIImage? {
        let s = fetchOrCreateSettingsObject()
        if let data = s.value(forKey: "avatarData") as? Data {
            return UIImage(data: data)
        }
        return nil
    }

    /// Сохранить username (и послать Notification)
    func saveUsername(_ name: String) {
        let s = fetchOrCreateSettingsObject()
        s.setValue(name, forKey: "username")
        saveContext()
        NotificationCenter.default.post(name: .settingsChanged, object: nil, userInfo: ["username": name])
    }

    /// Сохранить/удалить аватар. image == nil -> удаление.
    func saveAvatarImage(_ image: UIImage?) {
        let s = fetchOrCreateSettingsObject()
        if let img = image {
            // сжать/оптимизировать перед сохранением
            if let data = img.jpegData(compressionQuality: 0.9) {
                s.setValue(data, forKey: "avatarData")
            } else {
                s.setValue(nil, forKey: "avatarData")
            }
        } else {
            s.setValue(nil, forKey: "avatarData")
        }
        saveContext()
        NotificationCenter.default.post(name: .settingsChanged, object: nil, userInfo: ["avatarChanged": true])
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}
