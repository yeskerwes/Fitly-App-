import Foundation
import CoreData
import UIKit

final class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}

    private let modelName = "Fitly"
    
    // MARK: - Persistent container 
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)

        if let desc = container.persistentStoreDescriptions.first {
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❗ Core Data load error:", error)
                #if DEBUG
                if let url = storeDescription.url {
                    print("Attempting to remove old store at:", url.path)
                    do {
                        try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
                        try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [
                            NSMigratePersistentStoresAutomaticallyOption: true,
                            NSInferMappingModelAutomaticallyOption: true
                        ])
                        print("Removed and recreated persistent store (DEV).")
                    } catch {
                        fatalError("Unresolved Core Data error after delete attempt: \(error)")
                    }
                } else {
                    fatalError("Unresolved Core Data error: \(error)")
                }
                #else
                fatalError("Unresolved Core Data error: \(error)")
                #endif
            } else {
                print("Core Data store loaded:", storeDescription.url?.lastPathComponent ?? "(memory)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()


    var context: NSManagedObjectContext { persistentContainer.viewContext }

    func saveContext() {
        let ctx = context
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("CoreData save error:", error)
        }
    }

    // MARK: - Challenge helpers
    @discardableResult
    func createChallenge(title: String,
                         imageName: String,
                         days: Int,
                         quantityPerDay: Int,
                         status: String = "active",
                         createdAt: Date = Date()) -> ChallengeEntity {
        let ctx = context
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "ChallengeEntity", in: ctx) else {
            fatalError("NSEntityDescription not found for 'ChallengeEntity'")
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
        do {
            return try context.fetch(req)
        } catch {
            print("Fetch error:", error)
            return []
        }
    }

    func updateStatus(for entity: ChallengeEntity, to newStatus: String) {
        entity.status = newStatus
        saveContext()
    }

    func delete(_ entity: ChallengeEntity) {
        context.delete(entity)
        saveContext()
    }

    // MARK: - Settings helpers
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

    func currentUsername() -> String {
        let s = fetchOrCreateSettingsObject()
        return (s.value(forKey: "username") as? String) ?? ""
    }

    func currentAvatarImage() -> UIImage? {
        let s = fetchOrCreateSettingsObject()
        if let data = s.value(forKey: "avatarData") as? Data {
            return UIImage(data: data)
        }
        return nil
    }

    func saveUsername(_ name: String) {
        let s = fetchOrCreateSettingsObject()
        s.setValue(name, forKey: "username")
        saveContext()
        NotificationCenter.default.post(name: .settingsChanged, object: nil, userInfo: ["username": name])
    }

    func saveAvatarImage(_ image: UIImage?) {
        let s = fetchOrCreateSettingsObject()
        if let img = image {
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

    // MARK: - PushupSession helpers
    @discardableResult
    func createPushupSession(count: Int, date: Date = Date()) -> NSManagedObject {
        let ctx = context
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "PushupSession", in: ctx) else {
            fatalError("PushupSession entity not found in model")
        }
        let obj = NSManagedObject(entity: entityDesc, insertInto: ctx)
        obj.setValue(Int16(count), forKey: "count")
        obj.setValue(date, forKey: "date")
        saveContext()
        return obj
    }

    func fetchPushupSessions(sortedByDateDescending: Bool = true, limit: Int? = nil) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "PushupSession")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: !sortedByDateDescending)]
        if let l = limit { req.fetchLimit = l }
        do {
            return try context.fetch(req)
        } catch {
            print("Fetch PushupSession failed:", error)
            return []
        }
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}
