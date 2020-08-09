//
//  PlaceInfoViewController.swift
//  Trip Planner
//
//  Created by Admin on 12/15/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import UIKit

class PlaceInfoViewController: UIViewController {

    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var schedTimeIntervalLabel: UILabel!
    @IBOutlet weak var openStatusImageView: UIImageView!
    
    var place: Place
    
    let tripModel = TripModel.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    init(place: Place) {
        self.place = place
        
        super.init(nibName: "PlaceInfoViewController", bundle: nil)
        // rem: You MUST call the designated init above when creating a custom init,
        //      and also handle the required init that was addded below.
        
        self.view.layer.cornerRadius = 6
    }
    
    override func viewDidLayoutSubviews() {
        if let placeName = place.name {
            placeNameLabel.text = placeName
        }
        
        if let isOpen = place.isOpen {
            if isOpen {
                openStatusImageView.image = UIImage(named: "openIcon")
            } else {
                openStatusImageView.image = UIImage(named: "closedIcon")
            }
        }
        
        schedTimeIntervalLabel.text = TripCalculations.schedTimeIntervalStringFor(place)
        
        if let image = tripModel.getImageFromPlaceId(place.id) {
            placeImageView.image = image
            placeImageView.contentMode = UIView.ContentMode.scaleAspectFit
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
