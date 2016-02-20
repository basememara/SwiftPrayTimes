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
    
    var prayers: [PrayTimes.PrayerResult]?
    
    let method = "ISNA"
    let juristic = "Standard"
    let coords = [43.7, -79.4]
    let timezone = -5.0
    let dst = false
    
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
        prayTimes.getTimes(coords, timezone: timezone, dst: dst) {
            prayers in
            
            self.prayers = prayers
            
            // Populate table again
            self.tableView.reloadData()
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let prayers = prayers else { return 0 }
        
        return prayers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "Cell")
        
        guard let prayers = prayers else { return cell }
        
        let time = prayers[indexPath.row]
        
        cell.textLabel?.text = time.name
        cell.detailTextLabel?.text = time.formattedTime
        
        return cell
    }
    
}

