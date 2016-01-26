# VirtualTourist
The Virtual Tourist app downloads and stores images from Flickr. The app allows users to drop pins on a map, as if they were stops on a tour. Users will then be able to download pictures for the location and persist both the pictures, and the association of the pictures with the pin.  
The app will have two view controller scenes:  
* Travel Locations Map View: Allows the user to drop pins around the world.
* Photo Album View: Allows the users to download and edit an album for a location.  

The scenes are described in detail below.  
  
####Travel Locations Map

When the app first starts it opens to the map view. Users are able to zoom and scroll around the map using standard pinch and drag gestures.
The center of the map and the zoom level are persistent. If the app is turned off, the map returns to the same state when it is turned on again.
Tapping and holding the map drops a new pin. Users can place any number of pins on the map.
When a pin is tapped, the app navigates to the Photo Album view associated with the pin.  
  
####Photo Album  
  
  If the user taps a pin that does not yet have a photo album, the app downloads Flickr images associated with the latitude and longitude of the pin.
If no images are found a “No Images” label is displayed. If there are images, then they are displayed in a collection view.
While the images are downloading, the photo album is in a temporary “downloading” state in which the New Collection button is disabled. The app determines how many images are available for the pin location, and displays a placeholder image for each.
Once the images have all been downloaded, the app enables the New Collection button at the bottom of the page.
Tapping this button empties the photo album and causing a new fetch with a new set of images.
Users are able to remove photos from an album by tapping them. Pictures flows up to fill the space vacated by the removed photo upon deleting.
All changes to the photo album are automatically made persistent and tapping the back button returns the user to the Map view.
If the user selects a pin that already has a photo album then the Photo Album view displays the album and the New Collection button is enabled.



