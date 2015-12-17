import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
      
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    func deleteImage(image: UIImage?, withIdentifier identifier: String) {
       
        let path = pathForIdentifier(identifier)
        
        inMemoryCache.removeObjectForKey(path)
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        } catch _ {}
        
    }
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        
        let path = pathForIdentifier(identifier)
        
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {}
            
            return
        }
        
        
        inMemoryCache.setObject(image!, forKey: path)
        
        
        let data = UIImagePNGRepresentation(image!)!
        data.writeToFile(path, atomically: true)
    }
    
  
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        return fullURL.path!
        
    }
}
