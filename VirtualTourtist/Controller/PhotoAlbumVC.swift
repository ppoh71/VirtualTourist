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

let flickrApi = FlickrApi.shared

class PhotoAlbumVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var testImage: UIImageView!
    
    var dataController: DataController!
    var location: CLLocationCoordinate2D!
    var pin: Pin!
    var photos = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    fileprivate func setup() {
        collectionView.dataSource = self
        collectionView.delegate = self
        mapView.delegate = self
        addAnnotation(location: location)
        centerMapToAnnotation(location: location)
        print(location.latitude)
        print(location.longitude)
        print(pin)
        
        flickrApi.getPhotosByLocation(latitude: location.latitude, longitude: location.longitude) { (result, error) in
            guard error == nil else {
                print("flickr api error")
                return
            }
            
            if let result = result{
                let photos = result.photos
                print(photos.photo.count)
                print(photos.photo)
                self.handlePhotoResponse(photos: photos.photo)
            }
        }
    }
    
    func handlePhotoResponse(photos: [FlickrPhoto]){
        for (index,photo) in photos.enumerated(){
            print(photo.id)
            downloadFlickrPhoto(photo: photo, index: index)
        }
    }
}

// MARK: FlickrApi
extension PhotoAlbumVC{
    func downloadFlickrPhoto(photo: FlickrPhoto, index: Int){
        flickrApi.loadFlickrPhoto(photo: photo, index: index) { (image, index, error) in
            guard let image = image else{
                print("not image from flicr download")
                return
            }
            print("downloaded photo#####")
            print("image")
            self.testImage.image = image
            self.photos.append(image)
            self.collectionView.reloadData()
            
        }
    }
}

// MARK: CoreData Functions
extension PhotoAlbumVC{
    func persistPin(location: CLLocationCoordinate2D){
        let backgroundContext: NSManagedObjectContext = dataController.backgroundContext
        
        backgroundContext.perform {
            
        }
        
//        let newPin = Pin(context: dataController.viewContext)
//        newPin.latitude = location.latitude
//        newPin.longitude = location.longitude
//        newPin.createDate = Date()
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

extension PhotoAlbumVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCellVC
        print("cell stuff")
        print(photos.count)
        print((indexPath as IndexPath).row)
        if photos.count != 0 && photos.count - 1  >= (indexPath as IndexPath).row {
            if let photo = photos[(indexPath as IndexPath).row] as UIImage? {
                cell.collectionImage.image = photo
                cell.layer.borderWidth = CGFloat(0.5)
                cell.layer.borderColor = UIColor(red: 50.0/255, green: 52.0/255, blue: 54.0/255, alpha: 1.0).cgColor
            }
        }
         else {
            cell.collectionImage.image = UIImage(named: "preview")
            cell.layer.borderWidth = CGFloat(0.5)
            cell.layer.borderColor = UIColor(red: 50.0/255, green: 52.0/255, blue: 54.0/255, alpha: 1.0).cgColor
        }

        return cell
    }
    
    
}
