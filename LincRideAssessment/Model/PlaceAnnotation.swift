//
//  PlaceAnnotation.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 15/10/2025.
//

import MapKit

final class PlaceAnnotation: MKPointAnnotation {
    
    let mapItem: MKMapItem

    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        super.init()
        self.coordinate = mapItem.placemark.coordinate
        self.title = mapItem.name
        self.subtitle = mapItem.placemark.title
        
    }
}
