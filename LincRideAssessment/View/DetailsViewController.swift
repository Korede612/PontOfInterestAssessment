//
//  DetailsViewController.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 15/10/2025.
//

import UIKit
import MapKit
import CoreData


class DetailsViewController: UIViewController {
    var persistentContainer: NSPersistentContainer!
    private var persistenceManager: PersistenceManager!
    private var isFavorite = false
    
    private let mapItem: MKMapItem
    private let card = UIView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        persistenceManager = PersistenceManager(container: persistentContainer)
        setupCard()
        updateFavoriteState()
        populate()
    }
    
    
    private func setupCard() {
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.backgroundColor = .systemBackground
        card.translatesAutoresizingMaskIntoConstraints = false
        
        
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.numberOfLines = 0
        addressLabel.numberOfLines = 0
        saveButton.setTitle("Save to Favorites", for: .normal)
        saveButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        
        
        let sv = UIStackView(arrangedSubviews: [nameLabel, addressLabel, saveButton])
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        
        
        card.addSubview(sv)
        view.addSubview(card)
        
        
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            
            
            sv.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            sv.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            sv.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            sv.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }
    
    
    private func populate() {
        nameLabel.text = mapItem.name
        addressLabel.text = mapItem.placemark.title
    }
    
    private func updateFavoriteState() {
        guard let context = persistentContainer?.viewContext else { return }
        isFavorite = persistenceManager.isSaved(mapItem: mapItem, context: context) != nil
        let title = isFavorite ? "Remove Favorite" : "Save Favorite"
        saveButton.setTitle(title, for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = isFavorite ? .systemRed : .systemBlue
    }
    
    @objc private func toggleFavorite() {
        guard let context = persistentContainer?.viewContext else { return }
        
        if isFavorite {
            persistenceManager.remove(mapItem: mapItem, context: context)
        } else {
            persistenceManager.save(mapItem: mapItem)
        }
        
        updateFavoriteState()
    }
}
