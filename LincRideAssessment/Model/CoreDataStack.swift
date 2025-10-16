//
//  CoreDataStack.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 15/10/2025.
//

import Foundation
import CoreData


final class CoreDataStack {
    static func createContainer(name: String, inMemory: Bool = false) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }
        container.loadPersistentStores { desc, error in
            if let error = error { fatalError("CoreData store error: \(error)") }
        }
        return container
    }
}
