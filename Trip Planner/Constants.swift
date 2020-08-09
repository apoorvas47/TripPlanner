//
//  Constants.swift
//  Trip Planner
//
//  Created by Admin on 12/14/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import Foundation
import UIKit // Note: needed this for CGFloat!

struct PlaceConstants {
    static let defaultPlaceName = "Trip Place" // Note will be displayed to user when there is no place name
}

struct PaddingConstants {
    static let extraSmall : CGFloat = 3
    static let small : CGFloat = 5
    static let medium : CGFloat = 10
    static let mediumPlus : CGFloat = 12
    static let large : CGFloat = 25
}

struct PixelLengths {
    static let thirtyMinutes : CGFloat = 55
}

struct DefaultTimes {
    static let schedStartHour : Int = 9
    static let schedStartMinute : Int = 0
    static let placeDuration : Int = 30 // in minutes
}

let maxNumOfPlacesForDate : Int = 5
let animatorDurationConstant : Double = 0.9
