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
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var dataController: DataController!
    var fetchPhotosResultController: NSFetchedResultsController<Photo>!
    var location: CLLocationCoordinate2D!
    var pin: Pin!
    var photos = [UIImage?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        photos = [UIImage]()
        collectionView.reloadData()
        deletePersistedPhotos()
        getFlickrPhotosForLocation()
    }
    
    func setup() {
        collectionView.dataSource = self
        collectionView.delegate = self
        mapView.delegate = self
        addAnnotation(location: location)
        centerMapToAnnotation(location: location)
        setupfetchPhotosResultController()
    }
}

// MARK: CoreData Functions
extension PhotoAlbumVC{
    
    func setupfetchPhotosResultController(){
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        fetchPhotosResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pinCache\(pin.latitude)\(pin.longitude)")
        
        fetchPhotosResultController.delegate = self
        print("fetch photos")
        
        do{
            try fetchPhotosResultController.performFetch()
            
            if let fetchResult = fetchPhotosResultController.fetchedObjects{
                if fetchResult.count == 0 {
                    print("get flickr photos, no fetched photos found")
                    getFlickrPhotosForLocation()
                } else {
                    print("photos fetched count: \(fetchResult.count)")
                    handleFetchedPhotos()
                }
            }
            print("Fetched Pins Success \(String(describing: fetchPhotosResultController.fetchedObjects?.count))")
        } catch{
            print("Fetch Pins Error")
        }
    }
    
    func persistPhoto(photo: UIImage, index: Int){
        let backgroundContext: NSManagedObjectContext = dataController.backgroundContext
        let pinObjectId = pin.objectID
        
        backgroundContext.perform {
            let pinContext = backgroundContext.object(with: pinObjectId) as! Pin
            let newPhoto = Photo(context: backgroundContext)
            newPhoto.photoData = photo.jpegData(compressionQuality: 1)
            newPhoto.index = Int16(index)
            newPhoto.pin = pinContext
            
            do{
                try backgroundContext.save()
            } catch {
                print("background not saved")
            }
        }
    }
    
    func handleFetchedPhotos() {
        if let fetchedPhotos = fetchPhotosResultController.fetchedObjects{
            self.photos = [UIImage]()
            
            for photo in fetchedPhotos {
                let newPhoto = imageFromPhotoData(imageData: photo.photoData)
                self.photos.append(newPhoto!)
                print("fetched Photo")
            }
            collectionView.reloadData()
        }
    }
    
    func deletePersistedPhotos(){
        let backgroundContext: NSManagedObjectContext = dataController.backgroundContext
        var photoObjetcs = [NSManagedObjectID]()
        
        if let fetchedPhotos = self.fetchPhotosResultController.fetchedObjects{
            for photo in fetchedPhotos {
                photoObjetcs.append(photo.objectID)
            }
        }
        
        backgroundContext.perform {
            for photoObjectId in photoObjetcs{
                let deletePhoto = backgroundContext.object(with: photoObjectId)
                backgroundContext.delete(deletePhoto)
            }
            
            do{
                try backgroundContext.save()
                print("deleted saved")
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } catch{
                print("delete failed")
            }
        }
        
    }
    
    func deletePersitedSinglePhoto(index: Int) {
        let backgroundContext: NSManagedObjectContext = dataController.backgroundContext
        
        if let fetchedPhotos = self.fetchPhotosResultController.fetchedObjects{
            if fetchedPhotos[index] != nil {
                print(fetchedPhotos[index])
            }
        }
        
    }
    
}

// MARK: FlickrApi & Photo Download
extension PhotoAlbumVC{
    
    func getFlickrPhotosForLocation() {
        flickrApi.getPhotosByLocation(latitude: location.latitude, longitude: location.longitude) { (result, error) in
            guard error == nil else {
                print("flickr api error")
                return
            }
            
            if let result = result{
                if result.photos.photo.count > 0{
                    self.initEmptyPhotoArray(count: result.photos.photo.count)
                    self.handlePhotoFlickrResponse(photos: result.photos.photo)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                } else{
                    print("No photos for this location")
                }
            }
        }
    }
    
    func downloadFlickrPhoto(photo: FlickrPhoto, index: Int){
        flickrApi.loadFlickrPhoto(photo: photo, index: index) { (photo, index, error) in
            guard let photo = photo, let index = index else{
                print("not image from flicr download")
                return
            }
            
            let isIndexValid = self.photos.indices.contains(index)
            
            if isIndexValid {
                self.photos[index] = photo
                self.persistPhoto(photo: photo, index: index)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func handlePhotoFlickrResponse(photos: [FlickrPhoto]){
        for (index,photo) in photos.enumerated(){
            downloadFlickrPhoto(photo: photo, index: index)
        }
    }
    
    func initEmptyPhotoArray(count: Int){
        photos = [UIImage?](repeating: nil, count: count)
        collectionView.reloadData()
    }
    
    func imageFromPhotoData(imageData: Data?) -> UIImage?{
        if let imageData = imageData {
            return UIImage(data: imageData)
        } else {
            return UIImage(named: "preview")
        }
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

// MARK: CollectionView Delegates
extension PhotoAlbumVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCellVC
        print("############### photo count: \(photos.count) index: \(index)")
        
        if  photos.count - 1  >= (indexPath as IndexPath).row {
            if let photo = photos[(indexPath as IndexPath).row] as UIImage? {
                cell.collectionImage.image = photo
            } else {
                cell.collectionImage.image = UIImage(named: "preview")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("collectionView tapped: \(indexPath)")
        deletePersitedSinglePhoto(index: (indexPath as IndexPath).row)
    }
}

extension PhotoAlbumVC: NSFetchedResultsControllerDelegate{
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("begin updates")
        //print(fetchPhotosResultController.fetchedObjects?.count)
        //tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("end updates")
        //tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        //print("end updates \(String(describing: newIndexPath))")
        
        //        switch type {
        //        case .insert:
        //            tableView.insertRows(at: [newIndexPath!], with: .fade)
        //        case .delete:
        //            tableView.deleteRows(at: [indexPath!], with: .fade)
        //        case .move:
        //            tableView.reloadRows(at: [indexPath!], with: .fade)
        //        case .update:
        //            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        //        }
        
    }
}

