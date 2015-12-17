//
//  Pin.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 09/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Pin: NSManagedObject {
    
    struct Keys{
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var hasPhoto: Bool
    @NSManaged var creationTime: NSDate
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        latitude = (dictionary[Keys.Latitude] as? NSNumber)!
        longitude = (dictionary[Keys.Longitude] as? NSNumber)!
        hasPhoto = true
        creationTime = NSDate()
    }
    
}