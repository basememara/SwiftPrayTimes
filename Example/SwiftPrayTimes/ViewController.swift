//
//  ViewController.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 06/12/2015.
//  Copyright (c) 06/12/2015 Basem Emara. All rights reserved.
//

import UIKit
import SwiftPrayTimes

class ViewController: UITableViewController {
    
    var prayTimesData: [PrayTimes.PrayerResult]?
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [37.323, -122.0527]
    let timezone = -8.0
    let dst = true
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create instance
        var prayTimes = PrayTimes(
            method: method,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        activityIndicator.startAnimating()
        
        // Retrieve prayer times
        prayTimes.getTimes(coords, timezone: timezone, dst: dst, completion: {
            (times: [PrayTimes.TimeName: PrayTimes.PrayerResult]) in
            
            // Pluck only times array and sort by time
            self.prayTimesData = Array(times.values).sort {
                $0.time < $1.time
            }
            
            // Populate table again
            self.tableView.reloadData()
            
            self.activityIndicator.stopAnimating()
        })
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayTimesData != nil ? prayTimesData!.count : 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "Cell")
        let time = prayTimesData?[indexPath.row]
        
        cell.textLabel?.text = time!.name
        cell.detailTextLabel?.text = time!.formattedTime
        
        return cell
    }
    
}

