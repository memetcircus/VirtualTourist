//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 09/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import Foundation

extension VTClient{
    
    struct Constants{
        static let ApiKey : String = "ABCDEFG"
        static let BaseURL : String = "https://api.flickr.com/services/rest/"
        static let numberOfPhotosPerPage : String = "21"
        static let maxNumberOfPages : Int = 40
        static let doSafeSearch : String = "1"
        static let dataFormat : String = "json"
        static let isNoJSONCallBack : String = "1"
        static let valueOfExtras : String = "url_m"
        static let bboxExtraInset : Int = 1
    }
    
    struct Methods {
        static let FLickrPhotosSearch = "flickr.photos.search"
    }
   
    struct ParameterKeys {
        static let method = "method"
        static let apikey = "api_key"
        static let bbox = "bbox"
        static let safesearch = "safe_search"
        static let extras = "extras"
        static let format = "format"
        static let nojsoncallback = "nojsoncallback"
        static let page = "page"
        static let perPage = "per_page" 
    }
    
     struct JSONResponseKeys{
        static let photos = "photos"
        static let total = "total"
        static let photo = "photo"
        static let title = "title"
        static let urlm = "url_m"
        static let stat = "stat"
        static let pages = "pages"
        static let id = "id"
        static let farm = "farm"
        static let server = "server"
        static let secret = "secret"
    }
    
    struct flickrPictureSizes {
        static let thumbnail = "t"
        static let smallSquare = "s"
        static let largeSquare = "q"
        static let small240LongestSide = "m"
        static let small320LongestSide = "n"
    }
}
