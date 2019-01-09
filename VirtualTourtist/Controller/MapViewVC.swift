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
    
    var lastVisibleMapArea: MKMapRect!
    var visibleArea = Dictionary<String, Double>()
    var dataController: DataController!
    var fetchedPinsController: NSFetchedResultsController<Pin>!
    var fetchedPinByLocationController: NSFetchedResultsController<Pin>!
    var lastAddedAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeNotifications()
    }
    
    func setup(){
        addNotifications()
        setStoredVisibleArea()
        mapView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(sender:)))
        mapView.addGestureRecognizer(longTapGesture)
        
        fetchPins()
    }
    
    func addNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func removeNotifications(){
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func appMovedToBackground() {
        persistCurrentVisibleMapArea()
    }
    
    @objc func longTap(sender: UIGestureRecognizer){
        guard let newLocation = getLocationInView(sender) else {
            return
        }
        
        switch sender.state{
        case .began:
            addAnnotation(location: newLocation)
        case .changed:
            lastAddedAnnotation?.coordinate.latitude = newLocation.latitude
            lastAddedAnnotation?.coordinate.longitude = newLocation.longitude
        case .ended:
            persistPin(location: newLocation, annotation: lastAddedAnnotation!)
        default:
            return
        }
    }
    
    func showAlert(title: String, message: String){
        let alert = self.defineAlert(title: title, message: message)
        self.present(alert, animated: true)
    }
}

// MARK: --- --- --- CoreData Function --- --- ---
extension MapViewVC{
    
    func fetchPins(){
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        
        fetchedPinsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        
        do{
            try fetchedPinsController.performFetch()
            addStoredPinsToMap()
        } catch{
            showAlert(title: "Fetch Pins Error", message: error.localizedDescription)
        }
    }
    
    func fetchPin(latitude: Double, longitude: Double) -> Pin?{
        var fetchedPin: Pin?
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicateLat = NSPredicate(format: "latitude == %lf", latitude)
        let predicateLong = NSPredicate(format: "longitude == %lf", longitude)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateLat, predicateLong])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        fetchedPinByLocationController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do{
            try fetchedPinByLocationController.performFetch()
            
            if let fetchedResult = fetchedPinByLocationController.fetchedObjects{
                if fetchedResult.count >= 1 {
                    fetchedPin = fetchedResult[0]
                }
            }
            
        } catch {
            showAlert(title: "Fetch Pin Error", message: error.localizedDescription)
        }
        
        return fetchedPin
    }
    
    func persistPin(location: CLLocationCoordinate2D, annotation: MKPointAnnotation){
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = location.latitude
        newPin.longitude = location.longitude
        newPin.createDate = Date()
        
        dataController.viewContext.perform {
            do{
                try self.dataController.viewContext.save()
                
                //set the newly persited annotoation again, due to problems with selecting a dragged pin
                self.mapView.removeAnnotation(annotation)
                self.addAnnotation(location: location)
                
            } catch{
                self.showAlert(title: "Persist Pin Error", message: error.localizedDescription)
            }
        }
    }
}

// MARK: --- --- --- MapKit Function --- --- ---
extension MapViewVC{
    
    func getLocationInView(_ sender: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        let locationInView = sender.location(in: mapView)
        let locationOnMap: CLLocationCoordinate2D? = mapView.convert(locationInView, toCoordinateFrom: mapView)
        
        return locationOnMap
    }
    
    func addStoredPinsToMap() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        if let fetchedPins = fetchedPinsController.fetchedObjects{
            for pin in fetchedPins {
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
    }
    
    func setStoredVisibleArea(){
        if UserDefaults.standard.object(forKey: "VisibleMapArea") != nil && UserDefaults.standard.bool(forKey: "hasLaunchedBefore"){
            let visibleArea = UserDefaults.standard.dictionary(forKey: "VisibleMapArea") as! Dictionary<String, Double>
            if let x = visibleArea["x"], let y = visibleArea["y"], let width = visibleArea["width"], let height = visibleArea["height"]{
                let storedVisibleArea = MKMapRect(x: x, y:  y, width: width, height: height)
                mapView.visibleMapRect = storedVisibleArea
            }
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        //        annotation.title = "Some Title"
        //        annotation.subtitle = "Some Subtitle"
        self.mapView.addAnnotation((annotation))
        self.lastAddedAnnotation = annotation
    }
}

// MARK: --- --- --- MapView Delegates --- --- ---
extension MapViewVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { debugPrint("no mkpointannotaions"); return nil }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            //pinView!.rightCalloutAccessoryView = UIButton(type: .infoDark)
            pinView!.pinTintColor = UIColor.black
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let latitude = view.annotation?.coordinate.latitude, let longitude = view.annotation?.coordinate.longitude{
            if let fetchedPin = fetchPin(latitude: latitude, longitude: longitude){
                let photoAlbumVC = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbum") as! PhotoAlbumVC
                photoAlbumVC.dataController = dataController
                photoAlbumVC.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                photoAlbumVC.pin = fetchedPin
                
                self.navigationController?.pushViewController(photoAlbumVC, animated: true)
                mapView.deselectAnnotation(view.annotation, animated: false)
            }
        }
    }
}
