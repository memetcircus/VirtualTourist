//
//  TravelLocMapViewController.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 07/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocMapViewController: UIViewController,MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
   
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    var editButton: UIBarButtonItem!
    var selectedAnnotation : MKAnnotation!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationTime", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
        
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        
        mapView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController.delegate = self
        
        restoreMapRegion(false)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        let pins = fetchedResultsController.fetchedObjects as! [Pin]
        
        if (pins.count > 0){
            
            var annotations = [MKPointAnnotation]()
            
            for pin in pins{
                
                let annotation = MKPointAnnotation()
                
                let mapCoordinate : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: Double(pin.latitude), longitude: Double(pin.longitude))
                
                annotation.coordinate = mapCoordinate
                
                annotations.append(annotation)
            }
            
            mapView.addAnnotations(annotations)
        }
        
        editButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "editButtonTouchUp")
        editButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFontOfSize(18)], forState: UIControlState.Normal)
        editButton.tintColor = UIColor.blueColor()
        
        navigationItem.rightBarButtonItem = editButton
        navigationItem.title = "Virtual Tourist"
        
    }

    @IBAction func longPressed(sender: UILongPressGestureRecognizer) {
    
        if sender.state == UIGestureRecognizerState.Began {
            
            let touchPoint: CGPoint = sender.locationInView(self.mapView)
            
            let touchMapCoordinate : CLLocationCoordinate2D = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = touchMapCoordinate
            
            annotation.title = ""
            
            let dict : [String : AnyObject] = [
                Pin.Keys.Latitude  : annotation.coordinate.latitude as Double,
                Pin.Keys.Longitude : annotation.coordinate.longitude as Double
            ]
            
            let pinToBeAdded = Pin(dictionary: dict, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            
            do {
                try fetchedResultsController.performFetch()
            } catch {}
            
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(pinToBeAdded.latitude), longitude: Double(pinToBeAdded.longitude))
            mapView.addAnnotation(newAnnotation)
        }
        if sender.state == UIGestureRecognizerState.Ended{
            return
        }
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        var pins = fetchedResultsController.fetchedObjects as! [Pin]
        
        selectedAnnotation = view.annotation!
        
        if (!longPressGesture.enabled){
            
            for ( var i = 0; i < pins.count; i++){
                if (pins[i].latitude == selectedAnnotation.coordinate.latitude) && (pins[i].longitude == selectedAnnotation.coordinate.longitude)
                {
                    let toBeDeletedPin = pins[i]
                    pins.removeAtIndex(i)
                    sharedContext.deleteObject(toBeDeletedPin)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            
            do {
                try fetchedResultsController.performFetch()
            } catch {}
            
            self.mapView.removeAnnotation(selectedAnnotation)
        }
        else{
             performSegueWithIdentifier("ToPhotoAlbumViewCont", sender: self)
             mapView.deselectAnnotation(selectedAnnotation, animated: false)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView?.canShowCallout = false
            pinView?.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func editButtonTouchUp(){
        
      let pins = fetchedResultsController.fetchedObjects as! [Pin]
        
        if(self.navigationItem.rightBarButtonItem?.title == "Edit"){
            
            if (pins.count == 0){
                return
            }
            
            UIView.animateWithDuration(0.2, animations:{
                 self.mapView.frame.origin.y -= 70
            })
          
            longPressGesture.enabled = false
            self.navigationItem.rightBarButtonItem?.title = "Done"
        }
        else{
            UIView.animateWithDuration(0.2, animations:{
                self.mapView.frame.origin.y += 70
            })
            
            longPressGesture.enabled = true
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
    }
    
    func saveMapRegion(){
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longtitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            let longitude = regionDictionary["longtitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let pins = fetchedResultsController.fetchedObjects as! [Pin]
        
        if segue.identifier == "ToPhotoAlbumViewCont" {
            
            let instPhotoAlbumViewCont = segue.destinationViewController as! PhotoAlbumViewController
            
            for ( var i = 0; i < pins.count; i++){
                if (pins[i].latitude == selectedAnnotation.coordinate.latitude) && (pins[i].longitude == selectedAnnotation.coordinate.longitude)
                {
                    instPhotoAlbumViewCont.selectedPin = pins[i]
                }
            }
            
            instPhotoAlbumViewCont.selectedAnnotation = self.selectedAnnotation
        }
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
    
    func showAlertView(message: String){
        dispatch_async(dispatch_get_main_queue(), {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
}
