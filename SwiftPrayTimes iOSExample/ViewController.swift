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
        
        _ = PrayTimes.PrayerMethod("Custom", [
            PrayTimes.AdjustmentParam(time: .fajr, type: .degree, value: 15.0),
            PrayTimes.AdjustmentParam(time: .isha, type: .degree, value: 15.0)
        ],
        elavation: PrayTimes.ElavationMethod(rawValue: "NightMiddle"))
        
        // Create instance
        var prayTimes = PrayTimes(
            method: method,
            juristic: PrayTimes.AdjustmentMethod(rawValue: juristic)
        )
        
        activityIndicator.startAnimating()
        
        // Retrieve prayer times
        prayTimes.getTimes(for: coords, timeZone: timeZone, dst: dst) {
            prayers in
            
            self.prayers = prayers
            
            // Populate table again
            self.tableView.reloadData()
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayers?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        
        guard let prayers = prayers else { return cell }
        
        let time = prayers[indexPath.row]
        cell.textLabel?.text = time.name
        cell.detailTextLabel?.text = time.formattedTime
        cell.detailTextLabel?.textColor = time.isCurrent
            ? .red : time.isNext
            ? .orange : .gray
        
        return cell
    }
    
}

