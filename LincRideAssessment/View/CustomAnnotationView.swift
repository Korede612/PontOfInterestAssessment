//
//  CustomAnnotationView.swift
//  LincRideAssessment
//
//  Created by Oko-Osi Korede on 15/10/2025.
//

import MapKit
import UIKit

class CustomAnnotationView: MKMarkerAnnotationView {
    static let reuseID = "CustomAnnotationView"

    override var annotation: MKAnnotation? {
        didSet {
            clusteringIdentifier = "poi"
            markerTintColor = .systemBlue
            glyphImage = UIImage(systemName: "mappin.and.ellipse")
            canShowCallout = true
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
    }
}
