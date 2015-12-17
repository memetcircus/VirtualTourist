//
//  FlickrPhotoCell.swift
//  VirtualTourist
//
//  Created by Mehmet Akif Acar on 10/12/15.
//  Copyright © 2015 memetcircus. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var foreGroundImageView: UIImageView!
    @IBOutlet weak var actIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageViewInFlickrPhotoCell: UIImageView!
    var photoIDInFlickrPhotoCell: String!
    
    func startWaitAnimation(){
        actIndicator.startAnimating()
        self.userInteractionEnabled = false
        self.foreGroundImageView.alpha = 1
        self.imageViewInFlickrPhotoCell.userInteractionEnabled = false
        self.imageViewInFlickrPhotoCell.alpha = 0
    }
    
    func stopWaitAnimation(){
        self.foreGroundImageView.alpha = 0
        self.userInteractionEnabled = true
        self.imageViewInFlickrPhotoCell.userInteractionEnabled = true
        actIndicator.stopAnimating()
        self.imageViewInFlickrPhotoCell.alpha = 1
    }
}