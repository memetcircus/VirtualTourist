//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 08/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var sectionChanges: NSMutableArray!
    var itemChanges: NSMutableArray!
    
    var selectedAnnotation : MKAnnotation!
    var selectedPhotoIDs : [String]!
    var selectedPin: Pin!
    
    @IBOutlet var mapView: MKMapView!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationTime", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
        
    }()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        photoCollectionView.allowsMultipleSelection = true
        
        if (selectedPhotoIDs.count != 0){
            selectedPhotoIDs.removeAll()
        }
        
        self.alertLabel.alpha = 0
        self.photoCollectionView.alpha = 1
        self.photoCollectionView.userInteractionEnabled = true
        
        let track  = CLLocationCoordinate2D(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: track, span: span)
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = track
        mapView.addAnnotation(newAnnotation)
        mapView.setRegion(region, animated: false)
        mapView.regionThatFits(region)
        
        guard let photoArray = fetchedResultsController.fetchedObjects as? [Photo] else {
            return
        }
        if(photoArray.isEmpty){
            
            newCollectionButton.enabled = false
            getPhotosForTheSelectedPin(){ (Finished: Bool) in
                dispatch_async(dispatch_get_main_queue()) {
                    do {
                        try self.fetchedResultsController.performFetch()
                    } catch {}
                }
            }
        }
      
    }
    
    @IBAction func newCollectionButtonTouched(sender: AnyObject) {
        
        for index in photoCollectionView.indexPathsForVisibleItems(){
            photoCollectionView.deselectItemAtIndexPath(index, animated: false)
            photoCollectionView.cellForItemAtIndexPath(index)?.alpha = 1.0
        }
        
        if(newCollectionButton.titleLabel!.text == "New Collection"){
            
            if(hasConnectivity()){
                
                guard let photoArray : [Photo] = fetchedResultsController.fetchedObjects as? [Photo] else {
                    return
                }
                
                if(!photoArray.isEmpty){
                    
                    for photo in photoArray{
                        sharedContext.deleteObject(photo)
                        photo.pin = nil
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                    }
                }
                
                newCollectionButton.enabled = false
                
                getPhotosForTheSelectedPin(){ (Finished: Bool) in
                    dispatch_async(dispatch_get_main_queue()) {
                         do {
                            try self.fetchedResultsController.performFetch()
                         } catch {}
                    }
                }

            }
        }else{
            
            let photoArray : [Photo] = (fetchedResultsController.fetchedObjects as? [Photo])!
            
            for selectedPhotoID in selectedPhotoIDs{
                
                for photo in photoArray{
                    
                    if photo.id == selectedPhotoID {
                        sharedContext.deleteObject(photo)
                        photo.pin = nil
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                    }
                }
            }
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
        
        selectedPhotoIDs = [String]()
        
    }
    
    func getPhotosForTheSelectedPin(completionHandler: (Finished: Bool) -> Void){
        VTClient.sharedInstance.getImageFromFlickr(selectedAnnotation.coordinate) { (success, result, error) -> Void in
            if success {
                
                for photo in result!{
                    
                    let dict : [String : AnyObject] = [
                        Photo.Keys.Title  : photo[VTClient.JSONResponseKeys.title]!,
                        Photo.Keys.imageUrl : photo[VTClient.JSONResponseKeys.urlm]!,
                        Photo.Keys.id : photo[VTClient.JSONResponseKeys.id]!,
                        Photo.Keys.farm : photo[VTClient.JSONResponseKeys.farm]!,
                        Photo.Keys.server : photo[VTClient.JSONResponseKeys.server]!,
                        Photo.Keys.secret : photo[VTClient.JSONResponseKeys.secret]!
                    ]
                    
                    let photoNew = Photo(dictionary: dict, context: self.sharedContext)
                    
                    photoNew.pin = self.selectedPin
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                
                completionHandler(Finished: true)
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayError(error!.userInfo[NSLocalizedDescriptionKey]! as! String)
                }
                completionHandler(Finished: true)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        var cellPhotoImage = UIImage(imageLiteral: "PlaceHolder.png")
        
        let cell: FlickrPhotoCell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! FlickrPhotoCell
        
        cell.imageViewInFlickrPhotoCell.image = nil
        
        if !(newCollectionButton.titleLabel!.text == "Remove Selected Items") {
            
            if photo.imageUrl == nil || photo.imageUrl == "" {
                cell.stopWaitAnimation()
                cellPhotoImage = UIImage(imageLiteral: "NoImage.png")
                photo.photoImage = UIImage(imageLiteral: "NoImage.png")
                CoreDataStackManager.sharedInstance().saveContext()
            }
            else if photo.photoImage != nil {
                cell.stopWaitAnimation()
                cellPhotoImage = photo.photoImage!
                cell.photoIDInFlickrPhotoCell = photo.id
            }
            else{
                cell.startWaitAnimation()
                
                let imageSizedUrl = VTClient.sharedInstance.constructPictureURL(photo.farm, server: photo.server, id: photo.id, secret: photo.secret, size: VTClient.flickrPictureSizes.thumbnail)
                
                VTClient.sharedInstance.getImagesFromImageURL(imageSizedUrl) { (success, imageData, error) -> Void in
                        if(success){
                            if let data = imageData {
                                let image = UIImage(data: data)
                                photo.photoImage = image
                                CoreDataStackManager.sharedInstance().saveContext()
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    cell.stopWaitAnimation()
                                    cell.imageViewInFlickrPhotoCell.image = image
                                    cell.photoIDInFlickrPhotoCell = photo.id
                                    
                                    self.newCollectionButton.enabled = true
        
                                }
                            }
                        }else{
                            if let error = error{
                                print("Photo download error: \(error.localizedDescription)")
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                cell.stopWaitAnimation()
            
                                  self.newCollectionButton.enabled = true
                                
                            }
                        }
                }
            }
        }
        else{
            cellPhotoImage =  photo.photoImage!
            cell.photoIDInFlickrPhotoCell = photo.id
        }
        
        cell.imageViewInFlickrPhotoCell.image = cellPhotoImage
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: UIScreen.mainScreen().bounds.size.width / 3.1, height: 105)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrPhotoCell
        
        guard let _ = selectedCell.photoIDInFlickrPhotoCell else{
            return
        }
        
        selectedPhotoIDs.append(selectedCell.photoIDInFlickrPhotoCell)
        selectedCell.alpha = 0.2
        changeTitleOfNewCollectionButton()
        
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        let deselectedCell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrPhotoCell
        
        guard let _ = deselectedCell.photoIDInFlickrPhotoCell else{
            return
        }
    
        selectedPhotoIDs = arrayRemovingObject(deselectedCell.photoIDInFlickrPhotoCell, fromArray: selectedPhotoIDs)
        deselectedCell.alpha = 1.0
        changeTitleOfNewCollectionButton()
        
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        sectionChanges = NSMutableArray()
        itemChanges = NSMutableArray()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        let change : NSMutableDictionary = NSMutableDictionary()
        change[type.rawValue] = sectionIndex
        
        sectionChanges.addObject(change)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let change : NSMutableDictionary = NSMutableDictionary()
        
        switch type {
        case NSFetchedResultsChangeType.Insert:
            change[type.rawValue] = newIndexPath
            break
        case NSFetchedResultsChangeType.Delete:
            change[type.rawValue] = indexPath
            break
        default:
            break
        }
        
        itemChanges.addObject(change)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.photoCollectionView.performBatchUpdates({ () -> Void in
            
            for change in self.sectionChanges{
                
                change.enumerateKeysAndObjectsUsingBlock({ (key, obj, stop) -> Void in
                    
                    let type: NSFetchedResultsChangeType = NSFetchedResultsChangeType(rawValue: key.unsignedIntegerValue)!
                    
                    switch type {
                    case NSFetchedResultsChangeType.Insert:
                        self.photoCollectionView.insertSections(NSIndexSet(index: Int(obj as! NSNumber)))
                        break
                    case NSFetchedResultsChangeType.Delete:
                        self.photoCollectionView.deleteSections(NSIndexSet(index: Int(obj as! NSNumber)))
                        break
                    default:
                        break
                    }
                })
                
            }
            
            for change in self.itemChanges{
                
                change.enumerateKeysAndObjectsUsingBlock({ (key, obj, stop) -> Void in
                    
                    let type: NSFetchedResultsChangeType = NSFetchedResultsChangeType(rawValue: key.unsignedIntegerValue)!
                    
                    switch type {
                    case NSFetchedResultsChangeType.Insert:
                        self.photoCollectionView.insertItemsAtIndexPaths([obj as! NSIndexPath])
                        break
                    case NSFetchedResultsChangeType.Delete:
                        self.photoCollectionView.deleteItemsAtIndexPaths([obj as! NSIndexPath])
                        break
                    default:
                        break
                    }
                })
            }
            
            }) { (finished: Bool) -> Void in
            self.sectionChanges = nil
            self.itemChanges = nil
        }
    }
    
    
    func arrayRemovingObject<U: Equatable>(object: U, fromArray:[U]) -> [U] {
        return fromArray.filter { return $0 != object }
    }
    
    func changeTitleOfNewCollectionButton(){
        if(photoCollectionView.indexPathsForSelectedItems()?.count != 0){
            newCollectionButton.setTitle("Remove Selected Items", forState: UIControlState.Normal)
        }else{
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    func displayError(errorString: String) {
        dispatch_async(dispatch_get_main_queue(), {
            if (!self.selectedPin.hasPhoto){
                self.alertLabel.alpha = 1
                self.photoCollectionView.alpha = 0
                self.photoCollectionView.userInteractionEnabled = false
                return
            }
            if (errorString == "No Photos Found. Search Again"){
                
                self.selectedPin.hasPhoto = false
                CoreDataStackManager.sharedInstance().saveContext()
                
                self.alertLabel.alpha = 1
                self.photoCollectionView.alpha = 0
                self.photoCollectionView.userInteractionEnabled = false
            }else{
                self.showAlertView(errorString)
            }
        })
    }
    
    func showAlertView(message: String){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func hasConnectivity() -> Bool {
        let connected: Bool = (Reachability.reachabilityForInternetConnection()?.isReachable())!
        if connected == true {
            return true
        }else{
            showAlertView("The internet connection appears to be offline.")
            return false
        }
    }
}
