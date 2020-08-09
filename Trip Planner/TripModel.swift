//
//  TripModel.swift
//  Trip Planner
//
//  Created by Admin on 11/24/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import Foundation
import UIKit // Note: Used only to store associated photo for a Place!
import GooglePlaces

struct Place : Codable {
    var id : String
    var name : String? = PlaceConstants.defaultPlaceName
    var latitude : Double
    var longitude : Double
    var orderNum : Int // note: will be 0 when it hasn't been ordered yet.
    var date : Date? // Currently assigned date
    // Currently assigned time
    var startHour : Int?
    var startMinute : Int?
    var endHour : Int?
    var endMinute : Int?
    var isOpen : Bool?
}

class TripModel {
    static let sharedInstance = TripModel()
    
    fileprivate var dateToPlaceOrderDict = [Date : [Place]]()
    
    // All of the below dicts use Place.id as their key.
    fileprivate var allPlacesDict = [String : Place]() // This includes the places not attached to a date yet too!
    fileprivate var allImagesDict = [String : UIImage]()
    fileprivate var allOpenHoursDict = [String: GMSOpeningHours]()
    
    func getNextPinOrderNumForDate(date: Date) -> Int {
        return dateToPlaceOrderDict.count + 1
    }
    
    func addPlaceToDateToPlaceOrderDict(date: Date, place: Place) {
        if (dateToPlaceOrderDict[date] == nil) {
            dateToPlaceOrderDict[date] = [place]
        } else {
            dateToPlaceOrderDict[date]!.append(place)
        }
        recalculatePlacesSchedFor(date: date)
    }
    
    func removePlaceFromDateToPlaceOrderDict(date: Date, placeOrderNum: Int) {
        dateToPlaceOrderDict[date]!.remove(at: placeOrderNum - 1)
        recalculatePlacesSchedFor(date: date)
    }
    
    // Use this to add a place to the Trip! (no date yet!)
    func addPlaceToTrip(_ place: Place, openHours: GMSOpeningHours?, photo: UIImage?) {
        allPlacesDict[place.id] = place
        
        // Add open hours information that can be read later for each place on trip
        if let openHours = openHours {
            allOpenHoursDict[place.id] = openHours
        }
        
        // Add image for a place if there was an image and place id for it
        if let photo = photo {
            allImagesDict[place.id] = photo
        }
    }
    
    func getPlaceIdsForDate(_ date: Date) -> [String] {
        var placeNames : [String] = []
        
        if dateToPlaceOrderDict[date] == nil {
            return placeNames
        }
        
        for place in dateToPlaceOrderDict[date]! {
            placeNames.append(place.id)
        }
        return placeNames
    }
    
    func getPlacesForDate(_ date: Date) -> [Place] {
        var placeNames = [Place]()
        
        if dateToPlaceOrderDict[date] == nil {
            return placeNames
        }
        
        for place in dateToPlaceOrderDict[date]! {
            placeNames.append(place)
        }
        
        return placeNames
    }
    
    func getAllDates() -> [Date] {
        var dates : [Date] = []
        for element in dateToPlaceOrderDict {
            dates.append(element.key)
        }
        return dates
    }
    
    func getImageFromPlaceId(_ placeId: String) -> UIImage? {
        return allImagesDict[placeId]
    }
    
    func recalculatePlacesSchedFor(date: Date) {
        var isFirstPlace = true
        
        // The updated places info for the date that will contain updated sched info now!
        var updatedPlaces = [Place]()
        
        var previousPlace : Place?
        for place in dateToPlaceOrderDict[date]! {
            var updatedPlace = place
            
            if (isFirstPlace) {
                updatedPlace.date = date
                
                updatedPlace.startHour = DefaultTimes.schedStartHour
                updatedPlace.startMinute = DefaultTimes.schedStartMinute
                
                updatedPlace.endHour = TripCalculations.hourTimeAfter(minutes: DefaultTimes.placeDuration, startHour: updatedPlace.startHour!, startMinute: updatedPlace.startMinute!)
                updatedPlace.endMinute = TripCalculations.minuteTimeAfter(minutes: DefaultTimes.placeDuration, startHour: updatedPlace.startHour!, startMinute: updatedPlace.startMinute!)
            } else {
                updatedPlace.date = date
                
                // Add distance of travelTime between 2 locations
                let travelTime = TripCalculations.bestTimeBetweenPlaces(previousPlace!, updatedPlace)
                
                // start time of place 2 is after the travel the time from place 1
                updatedPlace.startHour = TripCalculations.hourTimeAfter(minutes: travelTime, startHour: previousPlace!.endHour!, startMinute: previousPlace!.endMinute!)
                updatedPlace.startMinute = TripCalculations.minuteTimeAfter(minutes: travelTime, startHour: previousPlace!.endHour!, startMinute: previousPlace!.endMinute!)
                
                updatedPlace.endHour = TripCalculations.hourTimeAfter(minutes: DefaultTimes.placeDuration, startHour: updatedPlace.startHour!, startMinute: updatedPlace.startMinute!)
                updatedPlace.endMinute = TripCalculations.minuteTimeAfter(minutes: DefaultTimes.placeDuration, startHour: updatedPlace.startHour!, startMinute: updatedPlace.startMinute!)
            }
            
            // only check for open hours if it exists!
            if let openHours = allOpenHoursDict[updatedPlace.id] {
                updatedPlace.isOpen = TripCalculations.isPlaceOpen(place: updatedPlace, openHours: openHours)
            }
            
            updatedPlaces.append(updatedPlace)
            isFirstPlace = false
            previousPlace = updatedPlace
        }
        
        dateToPlaceOrderDict[date] = updatedPlaces
    }
    
    func isPlaceAlreadyInTrip(placeId: String) -> Bool{
        if allPlacesDict[placeId] == nil {
            return false
        }
        return true
    }
    
    func numPlacesForDate(date: Date) -> Int {
        if dateToPlaceOrderDict[date] == nil {
            return 0
        } else {
            return dateToPlaceOrderDict[date]!.count
        }
        
    }
}
