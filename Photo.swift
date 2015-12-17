//
//  Photo.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 09/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Photo: NSManagedObject{
    
    struct Keys{
        static let Title = "title"
        static let imageUrl = "url_m"
        static let id = "id"
        static let image = "image"
        static let farm = "farm"
        static let secret = "secret"
        static let server = "server"
    }
    
    @NSManaged var title: String
    @NSManaged var id: String
    @NSManaged var imageUrl: String?
    @NSManaged var farm: NSNumber
    @NSManaged var secret: String
    @NSManaged var server: String
    @NSManaged var creationTime: NSDate
    
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary[Keys.Title] as! String
        id = dictionary[Keys.id] as! String
        imageUrl = dictionary[Keys.imageUrl] as? String
        farm = dictionary[Keys.farm] as! NSNumber
        secret = dictionary[Keys.secret] as! String
        server = dictionary[Keys.server] as! String
        
        creationTime = NSDate()
    }
    
    var photoImage: UIImage?{
        get {
            return VTClient.Caches.imageCache.imageWithIdentifier(String("/" + id + "_" + secret + ".jpg"))
        }
        set {
            VTClient.Caches.imageCache.storeImage(newValue, withIdentifier: String("/" + id + "_" + secret + ".jpg"))
        }
    }
    
    override func prepareForDeletion() {
         VTClient.Caches.imageCache.deleteImage( photoImage, withIdentifier: VTClient.sharedInstance.constructIdentifier(id, secret: secret))
    }
}