//
//  ViewController.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 06/12/2015.
//  Copyright (c) 06/12/2015 Basem Emara. All rights reserved.
//

import UIKit

class MonthlyController: UITableViewController {
    
    var prayerSeries: [PrayTimes.PrayerResultSeries]! = []
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [43.7, -79.4] // Toronto
    let timeZone = -5.0 // Toronto
    //let coords = [33.9733, -118.2487] // Los Angeles
    //let timeZone = -8.0 // Los Angeles
    let dst = true
    let date = NSDate(fromString: "2016/03/16 14:00")!
    let endDate = NSCalendar.currentCalendar()
        .dateByAddingUnit(.Month,
            value: 1,
            toDate: NSDate(),
            options: NSCalendarOptions(rawValue: 0)
        )!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create instance
        var prayTimes = PrayTimes(
            method: method,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        // Get prayer times for date range and reload table
        prayTimes.getTimesForRange(coords,
            endDate: endDate,
            date: date, // Optional
            timeZone: timeZone,
            dst: dst,
            onlyEssentials: true,
            completionHandler: { self.tableView.reloadData() }) {
                date, times in
                self.prayerSeries.append(PrayTimes.PrayerResultSeries(date: date, times: times))
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
        
        for item in data.times {
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