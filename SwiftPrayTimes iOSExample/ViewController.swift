//
//  ViewController.swift
//  SwiftPrayTimes
//
//  Created by Basem Emara on 06/12/2015.
//  Copyright (c) 06/12/2015 Basem Emara. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    var prayers: [PrayTimes.PrayerResult]?
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [43.7, -79.4]
    let timeZone = -5.0
    let dst = true
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customMethod = PrayTimes.PrayerMethod("Custom", [
            PrayTimes.AdjustmentParam(time: .Fajr, type: .Degree, value: 15.0),
            PrayTimes.AdjustmentParam(time: .Isha, type: .Degree, value: 15.0)
        ])
        
        // Create instance
        var prayTimes = PrayTimes(
            method: method,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        activityIndicator.startAnimating()
        
        // Retrieve prayer times
        prayTimes.getTimes(coords, timeZone: timeZone, dst: dst) {
            prayers in
            
            self.prayers = prayers
            
            // Populate table again
            self.tableView.reloadData()
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayers?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "Cell")
        
        guard let prayers = prayers else { return cell }
        
        let time = prayers[indexPath.row]
        cell.textLabel?.text = time.name
        cell.detailTextLabel?.text = time.formattedTime
        cell.detailTextLabel?.textColor = time.isCurrent
            ? UIColor.redColor() : time.isNext
            ? UIColor.orangeColor() : UIColor.grayColor()
        
        return cell
    }
    
}

