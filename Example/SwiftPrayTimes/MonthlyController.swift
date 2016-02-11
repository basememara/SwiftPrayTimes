//
//  ViewController.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 06/12/2015.
//  Copyright (c) 06/12/2015 Basem Emara. All rights reserved.
//

import UIKit
import SwiftPrayTimes

class MonthlyController: UITableViewController {
    
    var prayTimeSeries: [PrayTimes.PrayerResultSeries]! = []
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [37.323, -122.0527]
    let timezone = -8.0
    let dst = true
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
        prayTimes.getTimesForRange(coords, endDate: endDate, timezone: timezone, dst: dst,
            completion: { (series) in self.tableView.reloadData() }) {
                (date, times) in
                    self.prayTimeSeries.append(PrayTimes.PrayerResultSeries(date: date, times: times))
            }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayTimeSeries != nil ? prayTimeSeries.count : 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
        let data = prayTimeSeries[indexPath.row]
        var output = ""
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        
        for item in data.times.filter({ $0.isFard || $0.type == PrayTimes.TimeName.Sunrise }) {
            let name = Array(item.abbr.characters)[0]
            let time = item.formattedTime.componentsSeparatedByString(" ")[0]
            
            output += "(\(name)) \(time) "
        }
        
        cell.textLabel?.text = formatter.stringFromDate(data.date)
        cell.detailTextLabel?.text = output
        
        return cell
    }
    
}