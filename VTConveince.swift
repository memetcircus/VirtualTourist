//
//  VTConveince.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 09/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import Foundation
import MapKit

extension VTClient{
    
    func getImagesFromImageURL(imageURLString: String, completionHandler: (success: Bool, imageData: NSData?, error: NSError?) -> Void) {
        
        let imageURL = NSURL(string: imageURLString)
        
        let request = NSURLRequest(URL: imageURL!)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(success: false, imageData: nil, error: error)
            } else {
                completionHandler(success: true, imageData: data, error: nil)
            }
        }
        task.resume()
    }
    
    func getImageFromFlickr(bbox: CLLocationCoordinate2D, completionHandler: (success: Bool, result: [[String:AnyObject]]?, error: NSError?) -> Void){
    
        
        let minLat = Int(floor(Double(bbox.latitude))) + VTClient.Constants.bboxExtraInset
        let maxLat = Int(ceil(Double(bbox.latitude))) + VTClient.Constants.bboxExtraInset
        
        let minLong = Int(floor(Double(bbox.longitude))) + VTClient.Constants.bboxExtraInset
        let maxLong = Int(ceil(Double(bbox.longitude))) + VTClient.Constants.bboxExtraInset

        let bboxString = String(minLong) + "," + String(minLat) + "," + String(maxLong) + "," + String(maxLat)
        
        let parameters : [String:AnyObject] = [
            VTClient.ParameterKeys.method: VTClient.Methods.FLickrPhotosSearch,
            VTClient.ParameterKeys.apikey: VTClient.Constants.ApiKey,
            VTClient.ParameterKeys.bbox: bboxString,
            VTClient.ParameterKeys.safesearch: VTClient.Constants.doSafeSearch,
            VTClient.ParameterKeys.extras: VTClient.Constants.valueOfExtras,
            VTClient.ParameterKeys.format: VTClient.Constants.dataFormat,
            VTClient.ParameterKeys.nojsoncallback: VTClient.Constants.isNoJSONCallBack
        ]
        
        taskForGETMethod(parameters) { JSONResult, error in
            
            if let error = error {
                completionHandler(success: false, result: nil, error: error)
            } else {
                
                guard let photosDictionary = JSONResult[VTClient.JSONResponseKeys.photos] as? NSDictionary else {
                    print("Cannot find keys 'photos' in \(JSONResult)")
                     completionHandler(success: false, result: nil, error: NSError(domain: "getImageFromFlickr parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getImageFromFlickr"]))
                    return
                }
                
                guard let totalPages = photosDictionary[VTClient.JSONResponseKeys.pages] as? Int else {
                    print("Cannot find key 'pages' in \(photosDictionary)")
                     completionHandler(success: false, result: nil, error: NSError(domain: "getImageFromFlickr parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getImageFromFlickr"]))
                    return
                }
                
                let pageLimit = min(totalPages, VTClient.Constants.maxNumberOfPages)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                
                self.getImageFromFlickrByPage(bboxString, pageNumber: randomPage, completionHandler: { (success, result, error) -> Void in
                    if(success){
                      completionHandler(success: true, result: result, error: nil)
                    }else{
                      completionHandler(success: false, result: nil, error: error)
                    }
                })
            }
        }
    
    }
    
    func getImageFromFlickrByPage(bbox: String, pageNumber: Int, completionHandler: (success: Bool, result: [[String:AnyObject]]?, error: NSError?) -> Void){
        
        let parameters : [String:AnyObject] = [
            VTClient.ParameterKeys.method: VTClient.Methods.FLickrPhotosSearch,
            VTClient.ParameterKeys.apikey: VTClient.Constants.ApiKey,
            VTClient.ParameterKeys.bbox: bbox,
            VTClient.ParameterKeys.safesearch: VTClient.Constants.doSafeSearch,
            VTClient.ParameterKeys.extras: VTClient.Constants.valueOfExtras,
            VTClient.ParameterKeys.format: VTClient.Constants.dataFormat,
            VTClient.ParameterKeys.nojsoncallback: VTClient.Constants.isNoJSONCallBack,
            VTClient.ParameterKeys.page : pageNumber,
            VTClient.ParameterKeys.perPage : VTClient.Constants.numberOfPhotosPerPage
        ]
        
        taskForGETMethod(parameters) { JSONResult, error in
            
            if let error = error {
                completionHandler(success: false, result: nil, error: error)
            } else {
           
                guard let photosDictionary = JSONResult[VTClient.JSONResponseKeys.photos] as? NSDictionary else {
                    print("Cannot find keys 'photos' in \(JSONResult)")
                    completionHandler(success: false, result: nil, error: NSError(domain: "getImageFromFlickrByPage parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getImageFromFlickrByPage"]))
                    return
                }
                
                guard let totalPhotosVal = (photosDictionary[VTClient.JSONResponseKeys.total] as? NSString)?.integerValue else {
                    print("Cannot find key 'total' in \(photosDictionary)")
                    completionHandler(success: false, result: nil, error: NSError(domain: "getImageFromFlickrByPage parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getImageFromFlickrByPage"]))
                    return
                }
                
                if totalPhotosVal > 0{
                    guard let photosArray = photosDictionary[VTClient.JSONResponseKeys.photo] as? [[String: AnyObject]] else {
                        print("Cannot find key 'photo' in \(photosDictionary)")
                    completionHandler(success: false, result: nil, error: NSError(domain: "getImageFromFlickrByPage parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getImageFromFlickrByPage"]))
                        return
                    }
                    completionHandler(success: true, result: photosArray, error: nil)
                }
                else{
                    completionHandler(success: false, result: nil, error: NSError(domain: "getImageFromFlickrByPage parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Photos Found. Search Again"]))
                }
            }
        }
    }
}
