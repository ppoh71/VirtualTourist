//
//  PhotoAlbumVC.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 27.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!

    var dataController: DataController!
    var location: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    fileprivate func setup() {
        mapView.delegate = self
        addAnnotation(location: location)
        centerMapToAnnotation(location: location)
       
    }
}

// MARK: MapKit Helper Function
extension PhotoAlbumVC{
    
    func addAnnotation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Some Title"
        annotation.subtitle = "Some Subtitle"
        self.mapView.addAnnotation((annotation))
    }
    
    func centerMapToAnnotation(location: CLLocationCoordinate2D){
        let regionRadius: CLLocationDistance = 2522000
        let initialLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
}

// MARK: MapView Delegates
extension PhotoAlbumVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { print("no mkpointannotaions"); return nil }
        print("=========")
                let reuseId = "pin"
                var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
                if pinView == nil {
                    pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                    pinView!.canShowCallout = false
                    pinView!.rightCalloutAccessoryView = UIButton(type: .infoDark)
                    pinView!.pinTintColor = UIColor.black
                }
                else {
                    pinView!.annotation = annotation
                }
                return pinView
    }
}
