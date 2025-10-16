//
//  MapViewController.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 14/10/2025.
//

import UIKit
import MapKit
import CoreLocation
import Combine
import CoreData

class MapViewController: UIViewController {
    var persistentContainer: NSPersistentContainer!
    private var persistenceManager: PersistenceManager!

    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let viewModel = MapViewModel()

    private let categoryControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Restaurants","Cafes","Gas","All"])
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let searchBar = UISearchBar()
    private let suggestionsTable = UITableView()

    private var suggestions: [String] = [] {
        didSet { suggestionsTable.reloadData() }
    }

    private var currentLocation: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nearby POIs"
        view.backgroundColor = .systemBackground
        persistenceManager = PersistenceManager(container: persistentContainer)
        configureMap()
        configureUI()
        bindViewModel()
        configureLocation()
        loadSavedPOIs()
        
    }

    private func configureMap() {
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: CustomAnnotationView.reuseID)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.62)
        ])
    }

    private func configureUI() {
        categoryControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryControl)
        categoryControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)

        searchBar.placeholder = "Search places or type..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        suggestionsTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        suggestionsTable.dataSource = self
        suggestionsTable.delegate = self
        suggestionsTable.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(suggestionsTable)

        NSLayoutConstraint.activate([
            categoryControl.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 12),
            categoryControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            searchBar.topAnchor.constraint(equalTo: categoryControl.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            suggestionsTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            suggestionsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.$suggestions.sink { [weak self] s in
            self?.suggestions = s
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func configureLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        // For iOS 14 and above
        var status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            showLocationDisabledAlert()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }

    private func showLocationDisabledAlert() {
        let alert = UIAlertController(title: "Location Disabled",
                                      message: "To find nearby places, enable location in Settings or use saved favorites.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }))
        present(alert, animated: true)
    }

    @objc private func categoryChanged() {
        switch categoryControl.selectedSegmentIndex {
        case 0: viewModel.selectedCategory = "restaurant"
        case 1: viewModel.selectedCategory = "cafe"
        case 2: viewModel.selectedCategory = "gas station"
        default: viewModel.selectedCategory = ""
        }
        if let loc = currentLocation { performSearch(at: loc) }
    }
    
    private func performSearch(at coordinate: CLLocationCoordinate2D) {
        if NetworkMonitor.shared.isConnected {
            performOnlineSearch(at: coordinate)
        } else {
            fetchOfflineDataForSelectedCategory()
        }
    }
    
    private func performOnlineSearch(at coordinate: CLLocationCoordinate2D) {
        viewModel.searchNearby(location: coordinate) { [weak self] result in
            switch result {
            case .success(let items):
                self?.updateMapAnnotations(with: items)
            case .failure(let err):
                DispatchQueue.main.async {
                    self?.showSimpleAlert(title: "Search Error", message: err.localizedDescription)
                }
            }
        }
    }
    
    private func fetchOfflineDataForSelectedCategory() {
//        guard let context = persistentContainer?.viewContext else { return }
        let category = viewModel.selectedCategory
        let savedPOIs = persistenceManager.fetchFavorites(category: category)
        
        // Convert Core Data entities to annotations
        let annotations = savedPOIs.map { entity -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude)
            annotation.title = entity.name
            annotation.subtitle = entity.address
            return annotation
        }
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)
        
        showSimpleAlert(title: "Offline Mode", message: "Showing saved \(category.isEmpty ? "favorites" : category)s.")
    }



    private func updateMapAnnotations(with items: [MKMapItem]) {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        for item in items {
            let annotation = PlaceAnnotation(mapItem: item)
            mapView.addAnnotation(annotation)
        }
    }

    private func loadSavedPOIs() {
            let pois = persistenceManager.fetchAllPOIs()
            for poi in pois {
                let ann = MKPointAnnotation()
                ann.title = poi.name
                ann.subtitle = poi.address
                ann.coordinate = poi.coordinate
                mapView.addAnnotation(ann)
            }
    }

    private func showSimpleAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentLocation = loc.coordinate
        let region = MKCoordinateRegion(center: loc.coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
        mapView.setRegion(region, animated: true)
        performSearch(at: loc.coordinate)
        manager.stopUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showSimpleAlert(title: "Location Error", message: error.localizedDescription)
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: CustomAnnotationView.reuseID, for: annotation)
        return view
    }
    
    func mapView(_ mapView: MKMapView,
                 annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        guard let placeAnnotation = view.annotation as? PlaceAnnotation else { return }
        let detailsVC = DetailsViewController(mapItem: placeAnnotation.mapItem)
        detailsVC.persistentContainer = persistentContainer
        navigationController?.pushViewController(detailsVC, animated: true)
    }

}

extension MapViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchQuery = searchText
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let loc = currentLocation else { return }
        viewModel.searchNearby(location: loc, category: searchBar.text ?? "") { [weak self] result in
            if case .success(let items) = result { self?.updateMapAnnotations(with: items) }
            else if case .failure(let err) = result { self?.showSimpleAlert(title: "Search Error", message: err.localizedDescription) }
        }
    }
}


extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { suggestions.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = suggestions[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = suggestions[indexPath.row]
        searchBar.text = text
        searchBar.resignFirstResponder()
        if let loc = currentLocation {
            viewModel.searchNearby(location: loc, category: text) { [weak self] res in
                if case .success(let items) = res { self?.updateMapAnnotations(with: items) }
            }
        }
    }
}
