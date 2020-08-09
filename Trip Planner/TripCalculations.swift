//
//  TripCalculations.swift
//  Trip Planner
//
//  Created by Admin on 12/15/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import Foundation
import MapKit
import GooglePlaces

class TripCalculations {
    
    // Note: must only be called with a place that has the date AND time assigned already!
    static func isPlaceOpen(place: Place, openHours: GMSOpeningHours) -> Bool {
        if openHours.periods == nil { // The place has no open periods.
            return false
        }
        
        let day = place.date!.getDayOfWeek() // will be a UInt from 0 to 6
        let startHour = UInt(place.startHour!)
        let startMinute = UInt(place.startMinute!)
        let endHour = UInt(place.endHour!)
        let endMinute = UInt(place.endMinute!)
        
        for period in openHours.periods! {
            if period.openEvent.day == day {
                let openTime = period.openEvent.time
                let closeTime = period.closeEvent?.time
                if (startHour > openTime.hour || (startHour == openTime.hour && startMinute >= openTime.minute)) {
                    if (closeTime == nil) { // means open till rest of day
                        return true
                    } else if (endHour < closeTime!.hour || (endHour == closeTime!.hour && endMinute <= closeTime!.minute)) {
                        return true
                    }
                }
            }
        }
        
        return false // No open slot was found that fit
    }
    
    // Returns the travel time in minutes between 2 places
    // (Used to compare walking and driving times using .walking and .automobile )
    static func travelTimeBetweenPlaces(_ place1: Place, _ place2: Place, transportType: MKDirectionsTransportType) -> Int {
        // Route Request
        let request = MKDirections.Request()
        let sourceCoord = CLLocationCoordinate2D(latitude: place1.latitude, longitude: place1.longitude)
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoord, addressDictionary: nil))
        let destinationCoord = CLLocationCoordinate2D(latitude: place2.latitude, longitude: place2.longitude)
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoord, addressDictionary: nil))
        request.requestsAlternateRoutes = false // we only want one!
        request.transportType = transportType
        
        //let directions = MKDirections(request: request)
        
        var routeTimeInMinutes : Int = 0
        
        let directions = MKDirections(request: request)
        directions.calculate (completionHandler: {
            (response: MKDirections.Response?, error: Error?) in
            if let routeResponse = response?.routes {
                routeTimeInMinutes = Int(routeResponse[0].expectedTravelTime / 60)
            }
        })
        
        return routeTimeInMinutes
    }
    
    // Returns the travel time in minutes between 2 places
    // (Used to compare walking and driving times using .walking and .automobile )
    static func bestTimeBetweenPlaces(_ place1: Place, _ place2: Place) -> Int {
        let walkingTime = travelTimeBetweenPlaces(place1, place2, transportType: .walking)
        let carTime = travelTimeBetweenPlaces(place1, place2, transportType: .automobile)
        return min(walkingTime, carTime)
    }
    
    // Note: assumes no cross over into next day.
    static func hourTimeAfter(minutes: Int, startHour: Int, startMinute: Int) -> Int {
        if (startMinute + minutes < 60) {
            return startHour
        } else {
            return startHour + 1
        }
    }
    
    // Note: assumes no cross over into next day.
    static func minuteTimeAfter(minutes: Int, startHour: Int, startMinute: Int) -> Int {
        if (startMinute + minutes < 60) {
            return startMinute + minutes
        } else {
            return startMinute + minutes - 60
        }
    }
    
    // Must only call with a place that has been scheduled
    static func schedTimeIntervalStringFor(_ place: Place) -> String {
        var returnString = ""
        
        returnString += String(place.startHour!) + ":"
        
        if (place.startMinute! < 10) {
            returnString += "0"
        }
        returnString += String(place.startMinute!)
        
        returnString += " to " + String(place.endHour!) + ":"
        
        if (place.endMinute! < 10) {
            returnString += "0"
        }
        returnString += String(place.endMinute!)
        
        return returnString
    }
}
