//
//  ViewController.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 06/12/2015.
//  Copyright (c) 06/12/2015 Basem Emara. All rights reserved.
//

import UIKit

class MonthlyController: UITableViewController {
    
    var prayerSeries: [PrayTimes.PrayerResultSeries] = []
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [43.7, -79.4] // Toronto
    let timeZone = -5.0 // Toronto
    //let coords = [33.9733, -118.2487] // Los Angeles
    //let timeZone = -8.0 // Los Angeles
    let dst = true
    
    let startDate = Date(fromString: "2016/05/15 14:00")!
    let endDate = Date(fromString: "2016/06/15 14:00")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customMethod = PrayTimes.PrayerMethod("Custom", [
            PrayTimes.AdjustmentParam(time: .fajr, type: .degree, value: 15.0),
            PrayTimes.AdjustmentParam(time: .isha, type: .degree, value: 15.0)
        ])
        
        // Create instance
        var prayTimes = PrayTimes(
            method: customMethod,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        // Get prayer times for date range and reload table
        prayTimes.getTimeSeries(for: coords,
            endDate: endDate,
            startDate: startDate,
            timeZone: timeZone,
            dst: dst,
            onlyEssentials: true) { series in
                self.prayerSeries = series
                self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayerSeries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let data = prayerSeries[indexPath.row]
        let formatter = DateFormatter()
        var output = ""
        
        for item in data.prayers {
            let time = item.formattedTime.components(separatedBy: " ")[0]
            
            // Display current and next indicators
            let status = item.isCurrent ? "c" : item.isNext ? "n" : ""
            
            // Place date of prayer next to time
            formatter.dateFormat = "dd"
            output += "\(time)-\(formatter.string(from: item.date))\(status), "
        }
        
        formatter.dateFormat = "MMMM dd, yyyy h:mm a"
        cell.textLabel?.text = formatter.string(from: data.date)
        
        cell.detailTextLabel?.text = output
        
        return cell
    }
    
}
