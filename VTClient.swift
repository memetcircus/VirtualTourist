//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 09/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import Foundation

class VTClient : NSObject {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    var baseURL: String? = nil
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    class func sharedInstance() -> VTClient {
        
        struct Singleton {
            static var sharedInstance = VTClient()
        }
        return Singleton.sharedInstance
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    func taskForGETMethod(parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        
        baseURL = VTClient.Constants.BaseURL
        
        let urlString = baseURL! + VTClient.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
         let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard (error == nil) else {
                let userInfo = [NSLocalizedDescriptionKey : error!.localizedDescription]
                completionHandler(result: false, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                var userInfo : [String : String]? = nil
                if let response = response as? NSHTTPURLResponse {
                   userInfo = [NSLocalizedDescriptionKey : "Your request returned an invalid response! Status code: \(response.statusCode)!"]
                } else if let response = response {
                   userInfo = [NSLocalizedDescriptionKey : "Your request returned an invalid response! Response: \(response)!"]
                } else {
                   userInfo = [NSLocalizedDescriptionKey : "Your request returned an invalid response!"]
                    
                }
                completionHandler(result: false, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "No data was returned by the request!"]
                completionHandler(result: false, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            VTClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }
        
        task.resume()
        
        return task
    }
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        for (key, value) in parameters {
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble escaping string \"\(stringValue)\"")
            }
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func constructPictureURL(farm: NSNumber, server: String, id: String, secret: String, size: String) -> String {
        
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(size).jpg"
    }
    
    func constructIdentifier(id: String, secret: String) -> String{
        
        return String("/" + id + "_" + secret + ".jpg")
    }

}