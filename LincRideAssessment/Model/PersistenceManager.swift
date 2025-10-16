//
//  PersistenceManager.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 15/10/2025.
//

import Foundation
import CoreData
import MapKit


final class PersistenceManager {
    private let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }
    
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func isSaved(mapItem: MKMapItem, context: NSManagedObjectContext) -> POIEntity? {
        let fetchRequest: NSFetchRequest<POIEntity> = POIEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "name == %@ AND latitude == %lf AND longitude == %lf",
            mapItem.name ?? "",
            mapItem.placemark.coordinate.latitude,
            mapItem.placemark.coordinate.longitude
        )
        return try? context.fetch(fetchRequest).first
    }
    
    func save(mapItem: MKMapItem) {
        guard isSaved(mapItem: mapItem, context: context) == nil else { return }
        
        let entity = POIEntity(context: context)
        entity.id = UUID()
        entity.name = mapItem.name
        entity.category = mapItem.pointOfInterestCategory?.rawValue
        entity.address = mapItem.placemark.title
        entity.latitude = mapItem.placemark.coordinate.latitude
        entity.longitude = mapItem.placemark.coordinate.longitude
        
        do { try context.save() }
        catch { print("Failed to save favorite: \(error)") }
    }
    
    func fetchAllPOIs() -> [POIEntity] {
        var results: [POIEntity] = []
        context.performAndWait {
            do {
                let req: NSFetchRequest<POIEntity> = POIEntity.fetchRequest()
                results = try context.fetch(req)
            } catch {
                print("❌ Fetch error:", error)
            }
        }
        return results
    }
    
    
    
    func delete(_ poi: POIEntity) throws {
        context.delete(poi)
        try context.save()
    }
    
    func remove(mapItem: MKMapItem, context: NSManagedObjectContext) {
        guard let object = isSaved(mapItem: mapItem, context: context) else { return }
        
        do { try delete(object) }
        catch { print("Failed to remove favorite: \(error)") }
    }
}

extension POIEntity {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func create(from mapItem: MKMapItem, context: NSManagedObjectContext) -> POIEntity {
        let poi = POIEntity(context: context)
        poi.id = UUID()
        poi.name = mapItem.name
        poi.category = mapItem.pointOfInterestCategory?.rawValue
        poi.address = mapItem.placemark.title
        poi.latitude = mapItem.placemark.coordinate.latitude
        poi.longitude = mapItem.placemark.coordinate.longitude
        return poi
    }
}

extension PersistenceManager {
    func fetchFavorites(category: String) -> [POIEntity] {
        let request: NSFetchRequest<POIEntity> = POIEntity.fetchRequest()
        if !category.isEmpty {
            request.predicate = NSPredicate(format: "category CONTAINS[c] %@", category)
        }
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch offline POIs: \(error)")
            return []
        }
    }
}

