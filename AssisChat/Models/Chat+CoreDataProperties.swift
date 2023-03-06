//
//  Chat+CoreDataProperties.swift
//  AssisChat
//
//  Created by Nooc on 2023-03-05.
//
//

import Foundation
import CoreData


extension Chat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chat> {
        return NSFetchRequest<Chat>(entityName: "Chat")
    }

    @NSManaged public var rawColor: String?
    @NSManaged public var rawCreatedAt: Date?
    @NSManaged public var rawIcon: String?
    @NSManaged public var rawName: String?
    @NSManaged public var rawSystemMessage: String?
    @NSManaged public var rawTemperature: Float
    @NSManaged public var rMessages: NSSet?

}

// MARK: Generated accessors for rMessages
extension Chat {

    @objc(addRMessagesObject:)
    @NSManaged public func addToRMessages(_ value: Message)

    @objc(removeRMessagesObject:)
    @NSManaged public func removeFromRMessages(_ value: Message)

    @objc(addRMessages:)
    @NSManaged public func addToRMessages(_ values: NSSet)

    @objc(removeRMessages:)
    @NSManaged public func removeFromRMessages(_ values: NSSet)

}

extension Chat : Identifiable {

}
