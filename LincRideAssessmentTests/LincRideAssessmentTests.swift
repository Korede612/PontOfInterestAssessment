//
//  LincRideAssessmentTests.swift
//  LincRideAssessmentTests
//
//  Created by Oko-Osi Korede on 14/10/2025.
//

import XCTest
import MapKit
import CoreData
@testable import LincRideAssessment

final class LincRideAssessmentTests: XCTestCase {

    var container: NSPersistentContainer!
    var persistenceManager: PersistenceManager!
    
    override func setUpWithError() throws {
        container = CoreDataStack.createContainer(name: "LincRideAssessment", inMemory: true)
        persistenceManager = PersistenceManager(container: container)
    }

    override func tearDownWithError() throws {
        container = nil
        persistenceManager = nil
    }

    // MARK: - Core Data Persistence Tests
    
    func testSaveAndFetchPOI() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Test POI"
        
        persistenceManager.save(mapItem: mapItem)
        let results = persistenceManager.fetchAllPOIs()
        
        XCTAssertEqual(results.count, 1, "POI count should be 1 after saving.")
        XCTAssertEqual(results.first?.name, "Test POI", "POI name should match saved value.")
    }

    func testDeletePOI() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 2.0, longitude: 2.0)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Deletable POI"
        
        persistenceManager.save(mapItem: mapItem)
        var allPOIs = persistenceManager.fetchAllPOIs()
        XCTAssertEqual(allPOIs.count, 1)

        if let poi = allPOIs.first {
            try persistenceManager.delete(poi)
        }

        allPOIs = persistenceManager.fetchAllPOIs()
        XCTAssertTrue(allPOIs.isEmpty, "POI should be deleted successfully.")
    }

    func testDuplicateSaveDoesNotCreateMultipleEntries() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 3.0, longitude: 3.0)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Duplicate POI"
        
        persistenceManager.save(mapItem: mapItem)
        persistenceManager.save(mapItem: mapItem)
        
        let results = persistenceManager.fetchAllPOIs()
        XCTAssertEqual(results.count, 1, "Duplicate saves should not create multiple records.")
    }

    func testOfflineFetchWhenNoNetwork() throws {
        // Pretend network is offline
        let coordinate = CLLocationCoordinate2D(latitude: 4.0, longitude: 4.0)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Offline POI"
        persistenceManager.save(mapItem: mapItem)

        // When offline, fetch from local Core Data
        if !NetworkMonitor.shared.isConnected {
            let offlineData = persistenceManager.fetchAllPOIs()
            XCTAssertFalse(offlineData.isEmpty, "Offline fetch should return saved Core Data POIs.")
        }
    }

    // MARK: - Performance Tests
    
    func testPerformanceOfBulkSave() throws {
        self.measure {
            for i in 0..<1000 {
                let coord = CLLocationCoordinate2D(latitude: Double(i), longitude: Double(i))
                let placemark = MKPlacemark(coordinate: coord)
                let item = MKMapItem(placemark: placemark)
                item.name = "POI \(i)"
                persistenceManager.save(mapItem: item)
            }
        }
    }
}

