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
    let coords = [43.7, -79.4]
    let timezone = -5.0
    let dst = false
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
            completionHandler: { series in self.tableView.reloadData() }) {
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