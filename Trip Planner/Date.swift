//
//  Date.swift
//  Trip Planner
//
//  Created by Admin on 11/24/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import Foundation
import GooglePlaces

// Can use this to create a Date object like so: e.g. Date(dateString:"2014-06-06")
extension Date {
    init(_ dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        let date = dateStringFormatter.date(from: dateString)!
        self.init(timeInterval:0, since: date)
    }
    
    // Will Return what day of the week any given date is.
    func getDayOfWeek() -> GMSDayOfWeek {
        let calendarDayOfWeekReturnedFromDate = Calendar(identifier: .gregorian).component(.weekday, from: self)
        // Above actually does sun as 1, mon as 2 etc
        return GMSDayOfWeek(rawValue: UInt(calendarDayOfWeekReturnedFromDate) - 1)!
    }
    
    // Will return 3 letter month string in all caps, e.g. MAR, APR, etc.
    func getMonthString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: self).uppercased()
    }
    
    // Will return day of month string, e.g. 12, 30, etc.
    func getDayOfMonthString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: self)
    }
}
