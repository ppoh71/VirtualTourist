//
//  MapViewVC.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 20.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var testButton2: UIButton!
    
    var lastVisibleMapArea: MKMapRect!
    var visibleArea = Dictionary<String, Double>()
    
    var dataController: DataController!
    var fetchedPinsController: NSFetchedResultsController<Pin>!
    
    
    @IBAction func testButtonTapped(_ sender: Any) {
        setStoredVisibleArea()
    }
    
    @IBAction func testButton2Tapped(_ sender: Any) {
        persistCurrentVisibleMapArea()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("did load")
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeNotifications()
        print("will disappear")
    }
    
    func setup(){
        addNotifications()
        setStoredVisibleArea()
        mapView.delegate = self
        
        //add long tap gesture tp mapview
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(sender:)))
        mapView.addGestureRecognizer(longTapGesture)
        
        fetchPins()
    }
    
    // MARK: Notifications
    func addNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func removeNotifications(){
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    // MARK: Target Functions
    @objc func appMovedToBackground() {
        print("App moved to background!")
        persistCurrentVisibleMapArea()
    }
    
    @objc func longTap(sender: UIGestureRecognizer){
        print("long tap")
        if sender.state == .began {
            getLocationInView(sender)
        }
    }
    
    func fetchPins(){
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        
        fetchedPinsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        
        do{
            try fetchedPinsController.performFetch()
            print("Fetched Pins Success \(fetchedPinsController.fetchedObjects?.count)")
            addStoredPinsToMap()
        } catch{
            print("Fetch Pins Error")
        }
    }
    
    func persistPin(location: CLLocationCoordinate2D){
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        newPin.createDate = Date()
        
        do{
            try dataController.viewContext.save()
            print("saved view context")
        } catch{
            print("Persist New Pin Error")
        }
    }
}

// MARK: MapKit Helper Function
extension MapViewVC{
    
    fileprivate func getLocationInView(_ sender: UIGestureRecognizer) {
        let locationInView = sender.location(in: mapView)
        let locationOnMap: CLLocationCoordinate2D? = mapView.convert(locationInView, toCoordinateFrom: mapView)
        
        if let locationOnMap = locationOnMap{
            addAnnotation(location: locationOnMap)
            persistPin(location: locationOnMap)
        }
    }
    
    fileprivate func addStoredPinsToMap() {
       self.mapView.removeAnnotations(self.mapView.annotations)
        if let fetchedPins = fetchedPinsController.fetchedObjects{
            for pin in fetchedPins {
                print(pin.latitude)
                let location = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                addAnnotation(location: location)
            }
        }
    }
    
    func persistCurrentVisibleMapArea(){
        visibleArea = [
            "x": mapView.visibleMapRect.minX,
            "y": mapView.visibleMapRect.minY,
            "width": mapView.visibleMapRect.width,
            "height": mapView.visibleMapRect.height
        ]
        UserDefaults.standard.set(visibleArea, forKey: "VisibleMapArea")
        print("persist visible area")
        print(visibleArea)
    }
    
    func setStoredVisibleArea(){
        if UserDefaults.standard.object(forKey: "VisibleMapArea") != nil && UserDefaults.standard.bool(forKey: "hasLaunchedBefore"){
            let visibleArea = UserDefaults.standard.dictionary(forKey: "VisibleMapArea") as! Dictionary<String, Double>
            if let x = visibleArea["x"], let y = visibleArea["y"], let width = visibleArea["width"], let height = visibleArea["height"]{
                let storedVisibleArea = MKMapRect(x: x, y:  y, width: width, height: height)
                mapView.visibleMapRect = storedVisibleArea
                print("visible Area")
            }
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Some Title"
        annotation.subtitle = "Some Subtitle"
        self.mapView.addAnnotation((annotation))
        
    }
}

// MARK: MapView Delegates
extension MapViewVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { print("no mkpointannotaions"); return nil }
        
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let latitude = view.annotation?.coordinate.latitude, let longitude = view.annotation?.coordinate.longitude{
            let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbum") as! PhotoAlbumVC
            photoAlbumVC.dataController = dataController
            photoAlbumVC.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.navigationController?.pushViewController(photoAlbumVC, animated: true)
        }
    }
}
