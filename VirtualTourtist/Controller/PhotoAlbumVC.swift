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
    var photos = [UIImage]()
    var photosCountForCollectionView: Int {
        var count = 0
        if let fetchedObjects = fetchPhotosResultController.fetchedObjects{
            if fetchedObjects.count > 0 {
                count = fetchedObjects.count
                //print("collection count: fetched \(count)")
            } else {
                count = photos.count
                //print("collection count: photos \(count)")
            }
        }
        return count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        photos = [UIImage]()
        collectionView.reloadData()
        deletePersistedPhotos()
        //getFlickrPhotosForLocation()
    }

    fileprivate func setup() {
        collectionView.dataSource = self
        collectionView.delegate = self
        mapView.delegate = self
        addAnnotation(location: location)
        centerMapToAnnotation(location: location)
//        print(location.latitude)
//        print(location.longitude)
          print(pin)
        
        setupfetchPhotosResultController()
        //getFlickrPhotosForLocation()
    }
}

// MARK: CoreData Functions
extension PhotoAlbumVC{
    
    func persistPhoto(photo: UIImage){
        let backgroundContext: NSManagedObjectContext = dataController.backgroundContext
        let pinObjectId = pin.objectID
        
        backgroundContext.perform {
            //var newPhoto = Photo(
            let pinContext = backgroundContext.object(with: pinObjectId) as! Pin
            
            let newPhoto = Photo(context: backgroundContext)
            newPhoto.photoData = photo.jpegData(compressionQuality: 1)
            newPhoto.pin = pinContext
            
            do{
                try backgroundContext.save()
                //print("saved background context")
            } catch {
                print("background not saved")
            }
        }
    }
    
    func setupfetchPhotosResultController(){
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        fetchPhotosResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pinCache\(pin.latitude)\(pin.longitude)")
        
        fetchPhotosResultController.delegate = self
        
        print("fetch photos")
        
        do{
            try fetchPhotosResultController.performFetch()
            
            if let fetchResult = fetchPhotosResultController.fetchedObjects{
                if fetchResult.count > 0 {
                    print("photos fetched count: \(fetchResult.count)")
//                    handleFetchedPhotos()
                    collectionView.reloadData()
                } else {
                    print("get flickr photos, no fetched photos found")
                    getFlickrPhotosForLocation()
                }
            }
            
            
            print("Fetched Pins Success \(String(describing: fetchPhotosResultController.fetchedObjects?.count))")
        } catch{
            print("Fetch Pins Error")
        }
        print("end")
    }
    
//    fileprivate func handleFetchedPhotos() {
//        print("handle fetched Photos")
//        if let fetchedPhotos = fetchPhotosResultController.fetchedObjects{
//            print("handle fetched Photos ?")
//            self.photos = [UIImage]()
//
//            for photo in fetchedPhotos {
//                if let photoData = photo.photoData{
//                    let newPhoto = UIImage(data: photoData)
//                    self.photos.append(newPhoto!)
//                    print("fetched Photo")
//                }
//            }
//            collectionView.reloadData()
//        }
//    }
    
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
                print("klickr photo counts \(result.photos.photo.count)")

                if result.photos.photo.count > 0{
                    DispatchQueue.main.async {
                        self.initEmptyPhotoArray(count: result.photos.photo.count)
                        self.collectionView.reloadData()
                    }
                    self.handlePhotoFlickrResponse(photos: result.photos.photo)
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
                self.persistPhoto(photo: photo)
                DispatchQueue.main.async {
                    //self.collectionView.reloadData()
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
        photos = [UIImage](repeating: UIImage(), count: count)
        collectionView.reloadData()
    }
    
    func imageFromPhotoData(imageData: Data?) -> UIImage?{
        var image = UIImage()
        if let imageData = imageData {
            image = UIImage(data: imageData)!
        }
        return image
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
        return photosCountForCollectionView
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCellVC
//        print("cell stuff")
//        print(photos.count)
//        print((indexPath as IndexPath).row)
        let itemsCount = fetchPhotosResultController.fetchedObjects?.count ?? 0
        
        if itemsCount != 0 && itemsCount - 1  >= (indexPath as IndexPath).row {
            let photo = fetchPhotosResultController.object(at: indexPath)
            cell.collectionImage.image = imageFromPhotoData(imageData: photo.photoData)
            cell.layer.borderWidth = CGFloat(0.5)
            cell.layer.borderColor = UIColor(red: 50.0/255, green: 52.0/255, blue: 54.0/255, alpha: 1.0).cgColor
        }
         else {
            cell.collectionImage.image = UIImage(named: "preview")
            cell.layer.borderWidth = CGFloat(0.5)
            cell.layer.borderColor = UIColor(red: 50.0/255, green: 52.0/255, blue: 54.0/255, alpha: 1.0).cgColor
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
        print("begin updates")
        //tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("end updates")
        //tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("end updates \(String(describing: newIndexPath))")
        
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

