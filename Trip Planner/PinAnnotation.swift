//
//  PinAnnotation.swift
//  Trip Planner
//
//  Created by Admin on 12/14/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Pin : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var place: Place
    var image: UIImage!
    var pinOrderNum: Int
    var date: Date?
    
    init(title: String, coordinate: CLLocationCoordinate2D, place: Place) {
        self.title = title
        self.coordinate = coordinate
        self.place = place
        self.pinOrderNum = 0
        super.init()
        assignPinImageFromPinOrderNum()
    }
    
    // pinOrder - 0 means unassigned, 1-5 means that order number
    func updatePinOrderNumWithDate(pinOrderNum: Int, date: Date?) {
        self.pinOrderNum = pinOrderNum
        self.assignPinImageFromPinOrderNum()
        self.date = date
    }
    
    func assignPinImageFromPinOrderNum() {
        switch self.pinOrderNum {
        case -1:
            self.image = UIImage(named: "pinTaken")
        case 0:
            self.image = UIImage(named: "pinNotNumbered")
        case 1:
            self.image = UIImage(named: "pinNum1")
        case 2:
            self.image = UIImage(named: "pinNum2")
        case 3:
            self.image = UIImage(named: "pinNum3")
        case 4:
            self.image = UIImage(named: "pinNum4")
        case 5:
            self.image = UIImage(named: "pinNum5")
        default:
            self.image = UIImage(named: "pinNotNumbered")
        }
    }
}
