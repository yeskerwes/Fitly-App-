//
//  ChallengeEntity+CoreDataProperties.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 30.11.2025.
//
//

public import Foundation
public import CoreData


public typealias ChallengeEntityCoreDataPropertiesSet = NSSet

extension ChallengeEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChallengeEntity> {
        return NSFetchRequest<ChallengeEntity>(entityName: "ChallengeEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var days: Int16
    @NSManaged public var id: UUID?
    @NSManaged public var imageName: String?
    @NSManaged public var quantityPerDay: Int16
    @NSManaged public var status: String?
    @NSManaged public var title: String?
    @NSManaged public var doneToday: Int16
    @NSManaged public var completedDays: Int16

}

extension ChallengeEntity : Identifiable {

}
