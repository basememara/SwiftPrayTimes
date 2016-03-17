//
//  ViewController.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 06/12/2015.
//  Copyright (c) 06/12/2015 Basem Emara. All rights reserved.
//

import UIKit

class TimelineController: UITableViewController {
    
    var prayerTimeline: [PrayTimes.PrayerResult] = []
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [43.7, -79.4] // Toronto
    let timeZone = -5.0 // Toronto
    //let coords = [33.9733, -118.2487] // Los Angeles
    //let timeZone = -8.0 // Los Angeles
    let dst = true
    
    let startDate = NSDate(fromString: "2016/03/16 14:00")!
    let endDate = NSDate(fromString: "2016/04/16 14:00")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create instance
        var prayTimes = PrayTimes(
            method: method,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        // Get prayer times for date range and reload table
        prayTimes.getTimeline(coords,
            endDate: endDate,
            startDate: startDate,
            timeZone: timeZone,
            dst: dst,
            onlyEssentials: true) { prayers in
                self.prayerTimeline = prayers
                self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayerTimeline.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
        let data = prayerTimeline[indexPath.row]
        let formatter = NSDateFormatter(dateFormat: "MMMM dd, yyyy h:mm a")
        
        cell.textLabel?.text = data.name
        cell.detailTextLabel?.text = formatter.stringFromDate(data.date)
        
        return cell
    }
    
}