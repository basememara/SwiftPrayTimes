//
//  Extensions.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 3/10/16.
//
//

import Foundation

// Helpers for testing

extension Date {
    
    init?(fromString: String, dateFormat: String = "yyyy/MM/dd HH:mm") {
        guard let date = DateFormatter(dateFormat: dateFormat).date(from: fromString), !fromString.isEmpty
            else { return nil }
        
        self.init(timeInterval: 0, since: date)
    }

}

extension DateFormatter {
    
    convenience init(dateFormat: String) {
        self.init()
        
        self.dateFormat = dateFormat
    }
    
}
