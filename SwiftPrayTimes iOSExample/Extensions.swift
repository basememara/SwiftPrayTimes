//
//  Extensions.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 3/10/16.
//
//

import Foundation

// Helpers for testing

extension NSDate {
    
    convenience init?(fromString: String, dateFormat: String = "yyyy/MM/dd HH:mm") {
        guard let date = NSDateFormatter(dateFormat: dateFormat).dateFromString(fromString)
            where !fromString.isEmpty else {
                return nil
        }
        
        self.init(timeInterval: 0, sinceDate: date)
    }

}

extension NSDateFormatter {
    
    convenience init(dateFormat: String) {
        self.init()
        
        self.dateFormat = dateFormat
    }
    
}