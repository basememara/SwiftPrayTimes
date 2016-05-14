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
    
    let startDate = NSDate(fromString: "2016/05/15 14:00")!
    let endDate = NSDate(fromString: "2016/06/15 14:00")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customMethod = PrayTimes.PrayerMethod("Custom", [
            PrayTimes.AdjustmentParam(time: .Fajr, type: .Degree, value: 15.0),
            PrayTimes.AdjustmentParam(time: .Isha, type: .Degree, value: 15.0)
        ])
        
        // Create instance
        var prayTimes = PrayTimes(
            method: customMethod,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        // Get prayer times for date range and reload table
        prayTimes.getTimeSeries(coords,
            endDate: endDate,
            startDate: startDate,
            timeZone: timeZone,
            dst: dst,
            onlyEssentials: true) { series in
                self.prayerSeries = series
                self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayerSeries.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
        let data = prayerSeries[indexPath.row]
        let formatter = NSDateFormatter()
        var output = ""
        
        for item in data.prayers {
            let time = item.formattedTime.componentsSeparatedByString(" ")[0]
            
            // Display current and next indicators
            let status = item.isCurrent ? "c" : item.isNext ? "n" : ""
            
            // Place date of prayer next to time
            formatter.dateFormat = "dd"
            output += "\(time)-\(formatter.stringFromDate(item.date))\(status), "
        }
        
        formatter.dateFormat = "MMMM dd, yyyy h:mm a"
        cell.textLabel?.text = formatter.stringFromDate(data.date)
        
        cell.detailTextLabel?.text = output
        
        return cell
    }
    
}