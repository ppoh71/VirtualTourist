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
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var mapTopConstraint: NSLayoutConstraint!
    
    var dataController: DataController!
    var fetchPhotosResultController: NSFetchedResultsController<Photo>!
    var location: CLLocationCoordinate2D!
    var pin: Pin!
    var photos = [UIImage?]()
    var downloadedPhotos = 0
    var isActiveDownload = false
    var orientation = UIDevice.current.orientation
    var lastOrientation = UIDevice.current.orientation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeNotification()
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        print("tapped")
        if !isActiveDownload{
            photos = [UIImage]()
            collectionView.reloadData()
            deletePersistedPhotos()
        }
    }
    
    func setup() {
        newCollectionButton.isEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        mapView.delegate = self
        setFlowLayout(orientation: UIDevice.current.orientation)
        subscribeToNotification()
        addAnnotation(location: location)
        centerMapToAnnotation(location: location)
        setupfetchPhotosResultController()
    }
    
    func setActiveDownload(isActive: Bool){
        isActiveDownload = isActive
        DispatchQueue.main.async {
            self.newCollectionButton.isEnabled = !isActive
        }
        
        if isActive{
            DispatchQueue.main.async {
                self.indicator.startAnimating()
            }
        } else {
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
            }
        }
    }
    
    func subscribeToNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func unsubscribeNotification(){
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func deviceOrientationDidChange(_ notification: Notification) {
        orientation = UIDevice.current.orientation
        setFlowLayout(orientation: UIDevice.current.orientation)
    }
    
    func setFlowLayout(orientation: UIDeviceOrientation){
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let space:CGFloat = 1
        let horizontalDevider = width > 810 ? CGFloat(4.5) : CGFloat(4.0) //iphone 7.. or iphone x..
        
        if(orientation.isLandscape == true || lastOrientation.isLandscape && orientation.isFlat && true){
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            flowLayout.itemSize = CGSize(width: width / horizontalDevider, height: width / 5.5)
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.minimumLineSpacing = 0
            
            mapTopConstraint.constant = 45
            collectionView.reloadData()
        }
        else{
            let dimensionWidth = (width - (2 * space)) / 3.0
            let dimensionHeight = (height - (2 * space)) / 7.0
            flowLayout.minimumInteritemSpacing = space
            flowLayout.minimumLineSpacing = space
            flowLayout.itemSize = CGSize(width: dimensionWidth, height: dimensionHeight)
            
            mapTopConstraint.constant = 85
            collectionView.reloadData()
        }
        
        lastOrientation = UIDevice.current.orientation
    }
    
    
}

// MARK: --- --- ---   COREDATA Functions --- --- ---
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
                    setActiveDownload(isActive: false)
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
                //print("background photo saved")
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
            }
            collectionView.reloadData()
        }
    }
    
    func deletePersistedPhotos(){
        setActiveDownload(isActive: true)
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
                self.getFlickrPhotosForLocation()
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } catch{
                print("delete failed")
            }
        }
        
    }
    
    func deletePersitedSinglePhoto(at indexPath: IndexPath) {
        guard isActiveDownload == false else{
            print("active download, no delete")
            return
        }
        
        print("count objetcs & indexpath")
        print(fetchPhotosResultController.fetchedObjects?.count as Any)
        print(indexPath)
        
        guard let deletePhoto = fetchPhotosResultController.object(at: indexPath) as Photo? else {
            print("guard delete photo")
            return
        }
        
        dataController.viewContext.delete(deletePhoto)
        
        do{
            try dataController.viewContext.save()
            photos.remove(at: indexPath.row)
            collectionView.deleteItems(at: [indexPath])
        } catch {
            print("delete perssted photo failed")
        }
    }
    
}

// MARK: --- --- --- FlickrApi & Photo Download --- --- ---
extension PhotoAlbumVC{
    
    func getFlickrPhotosForLocation() {
        setActiveDownload(isActive: true)
        
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
                self.downloadedPhotos += 1
                self.photos[index] = photo
                self.persistPhoto(photo: photo, index: index)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
            
            if self.downloadedPhotos == self.photos.count {
                self.downloadedPhotos = 0
                self.setActiveDownload(isActive: false)
            }

        }
    }
    
    func handlePhotoFlickrResponse(photos: [FlickrPhoto]){
        for (index,photo) in photos.enumerated(){
            downloadFlickrPhoto(photo: photo, index: index)
        }
    }
    
    func initEmptyPhotoArray(count: Int){
        print("PHOTS ARRAY COUNT \(photos.count)")
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

// MARK: --- --- --- MapKit Helper Function --- --- ---
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

// MARK: --- --- --- MapView Delegates --- --- ---
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

// MARK: --- --- --- CollectionView Delegates
extension PhotoAlbumVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCellVC
        
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
        deletePersitedSinglePhoto(at: indexPath)
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
        switch type {
        case .delete:
            print("#########delete at \(indexPath)")

       default:
            break
        }
    }
}

