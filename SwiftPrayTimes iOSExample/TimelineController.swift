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
    
    let startDate = Date(fromString: "2016/03/16 14:00")!
    let endDate = Date(fromString: "2016/04/16 14:00")!
    
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
        prayTimes.getTimeline(for: coords,
            endDate: endDate,
            startDate: startDate,
            timeZone: timeZone,
            dst: dst,
            onlyEssentials: false) { prayers in
                self.prayerTimeline = prayers
                self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayerTimeline.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let data = prayerTimeline[indexPath.row]
        let formatter = DateFormatter(dateFormat: "MMMM dd, yyyy h:mm a")
        
        cell.textLabel?.text = data.name
        cell.detailTextLabel?.text = formatter.string(from: data.date)
        
        return cell
    }
    
}
