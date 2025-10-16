//
//  MapViewModel.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 15/10/2025.
//

import Foundation
import MapKit
import Combine

class MapViewModel: NSObject {
    @Published var searchQuery: String = ""
    @Published var selectedCategory: String = "restaurant"
    @Published private(set) var searchResults: [MKMapItem] = []
    @Published private(set) var suggestions: [String] = []

    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest

        $searchQuery
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] q in
                self?.completer.queryFragment = q
            }
            .store(in: &cancellables)
    }
    
    func searchNearby(location: CLLocationCoordinate2D, category: String? = nil, radius: Double = 2000,
                          completion: @escaping (Result<[MKMapItem], Error>) -> Void) {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: 5000,
                                            longitudinalMeters: 5000)
            
            // Multiple categories to combine
        let categories: [String]
        if let category {
            categories = [category]
        } else {
            categories = selectedCategory.isEmpty
                ? ["restaurant", "cafe", "gas station"]
                : [selectedCategory]
        }
            
            
            var allItems: [MKMapItem] = []
            let group = DispatchGroup()
            var searchError: Error?
            
            for category in categories {
                group.enter()
                
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = category
                request.region = region
                
                let search = MKLocalSearch(request: request)
                search.start { response, error in
                    defer { group.leave() }
                    if let error = error { searchError = error; return }
                    if let items = response?.mapItems {
                        allItems.append(contentsOf: items)
                    }
                }
            }
            
            group.notify(queue: .main) {
                if let error = searchError {
                    completion(.failure(error))
                } else {
                    // Remove duplicates based on coordinate + name
                    let uniqueItems = self.removeDuplicates(from: allItems)
                    completion(.success(uniqueItems))
                }
            }
        }
        
        private func removeDuplicates(from items: [MKMapItem]) -> [MKMapItem] {
            var seen = Set<String>()
            return items.filter {
                let key = "\($0.name ?? "")-\($0.placemark.coordinate.latitude)-\($0.placemark.coordinate.longitude)"
                return seen.insert(key).inserted
            }
        }
}

extension MapViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.map { $0.title }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
