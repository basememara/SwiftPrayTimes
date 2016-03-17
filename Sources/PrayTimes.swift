//--------------------- Copyright Block ----------------------
/*

PrayTimes.swift: Prayer Times Calculator (ver 1.0)
Copyright (C) 2007-2011 PrayTimes.org

Original Developer (JavaScript): Hamid Zarrabi-Zadeh
Translator Developer (Swift): Basem Emara
License: MIT

TERMS OF USE:
Permission is granted to use this code, with or
without modification, in any website or application
provided that credit is given to the original work
with a link back to PrayTimes.org.

This program is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY.

PLEASE DO NOT REMOVE THIS COPYRIGHT BLOCK.

*/


//--------------------- Help and Manual ----------------------
/*

User's Manual:
http://praytimes.org/manual

Calculation Formulas:
http://praytimes.org/calculation



//------------------------ User Interface -------------------------


getTimes (date, coordinates [, timeZone [, dst [, timeFormat]]])

setMethod (method)       // set calculation method
adjust (parameters)      // adjust calculation parameters
tune (offsets)           // tune times by given offsets

getMethod ()             // get calculation method
getSetting ()            // get current calculation parameters
getOffsets ()            // get current time offsets


//------------------------- Sample Usage --------------------------


var prayTimes = PrayTimes(
method: "ISNA",
juristic: PrayTimes.AdjustmentMethod(rawValue: "Standard")
)

prayTimes.getTimes([37.323, -122.0527], completion: {
(times: [PrayTimes.TimeName: PrayTimes.PrayerResult]) in

let fajrTime = times[PrayTimes.TimeName.Fajr]!.formattedTime
println("Fajr: \(fajrTime)")

let dhuhrTime = times[PrayTimes.TimeName.Dhuhr]!.formattedTime
println("Dhuhr: \(dhuhrTime)")

let asrTime = times[PrayTimes.TimeName.Asr]!.formattedTime
println("Asr: \(asrTime)")

let maghribTime = times[PrayTimes.TimeName.Maghrib]!.formattedTime
println("Fajr: \(maghribTime)")

let ishaTime = times[PrayTimes.TimeName.Isha]!.formattedTime
println("Isha: \(ishaTime)")
})


*/


//----------------------- PrayTimes Class ------------------------

import Foundation

public struct PrayTimes {
    
    //------------------------ Enumerations --------------------------
    
    public enum TimeName: Int {
        case Imsak, Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha, Midnight
        
        static let names = [
            Imsak: "Imsak",
            Fajr: "Fajr",
            Sunrise: "Sunrise",
            Dhuhr: "Dhuhr",
            Asr: "Asr",
            Sunset: "Sunset",
            Maghrib: "Maghrib",
            Isha: "Isha",
            Midnight: "Midnight"
        ]
        
        // http://natashatherobot.com/swift-enums-tableviews/
        public func getName() -> String {
            return TimeName.names[self] ?? ""
        }
    }
    
    public enum AdjustmentType {
        case Degree, Minute, Method, Factor
    }
    
    public enum AdjustmentMethod: String {
        case Standard = "Standard"
        case Hanafi = "Hanafi"
        case Jafari = "Jafari"
    }
    
    public enum ElavationMethod {
        case None, NightMiddle, OneSeventh, AngleBased
    }
    
    //------------------------ Structs/Classes --------------------------
    
    public struct AdjustmentParam {
        var time: TimeName
        var type = AdjustmentType.Degree
        var value: Any?
    }
    
    public struct PrayerMethod {
        var description: String
        var params = [AdjustmentParam]()
        
        init(_ description: String, _ params: [AdjustmentParam]) {
            self.description = description
            self.params = params
            
            // Add default params if applicable
            for item in PrayTimes.defaultParams {
                if !self.params.contains({ $0.time == item.time }) {
                    self.params.append(item)
                }
            }
        }
    }
    
    public struct PrayerResult {
        var timeFormat = "12h"
        var timeSuffixes = ["am", "pm"]
        var invalidTime =  "-----"
        
        public var name: String
        public var type: TimeName
        public var time: Double
        public var date: NSDate
        public var requestDate: NSDate
        public var coordinates: [Double]?
        public var timeZone: Double?
        public var abbr = ""
        public var isFard = false
        public var isCurrent = false
        public var isNext = false
        
        public var formattedTime: String {
            get { return getFormattedTime() }
        }
        
        public init(
            _ type: TimeName,
            _ time: Double,
            date: NSDate = NSDate(),
            requestDate: NSDate = NSDate(),
            coordinates: [Double]? = nil,
            timeZone: Double? = nil,
            timeFormat: String? = nil,
            timeSuffixes: [String]? = nil) {
                self.name = type.getName()
                self.type = type
                self.time = time
                self.date = date
                self.requestDate = requestDate
                self.coordinates = coordinates
                
                if let value = timeZone {
                    self.timeZone = value
                }
                
                if let value = timeFormat {
                    self.timeFormat = value
                }
                
                if let value = timeSuffixes {
                    self.timeSuffixes = value
                }
                
                // Handle times after midnight
                if self.time > 24 {
                    // Increment day
                    self.date = NSCalendar.currentCalendar()
                        .dateByAddingUnit(.Day,
                            value: 1,
                            toDate: self.date,
                            options: NSCalendarOptions(rawValue: 0)
                        )!
                }
                
                // Convert time to full date
                var timeComponents = PrayTimes.getTimeComponents(self.time)
                
                // Check if minutes spills to next hour
                if timeComponents[1] >= 60 {
                    // Increment hour
                    timeComponents[0] += 1
                    timeComponents[1] -= 60
                }
                
                // Check if hour spills to next day
                if timeComponents[0] >= 24 {
                    // Increment day
                    self.date = NSCalendar.currentCalendar()
                        .dateByAddingUnit(.Day,
                            value: 1,
                            toDate: self.date,
                            options: NSCalendarOptions(rawValue: 0)
                        )!
                    
                    timeComponents[0] -= 24
                }
                
                self.date = NSCalendar.currentCalendar()
                    .dateBySettingHour(timeComponents[0],
                        minute: timeComponents[1],
                        second: 0,
                        ofDate: self.date,
                        options: []
                    )!
                
                // Handle specific prayers
                switch (type) {
                case .Fajr:
                    self.abbr = "FJR"
                    self.isFard = true
                case .Sunrise:
                    self.abbr = "SHK"
                case .Dhuhr:
                    self.abbr = "DHR"
                    self.isFard = true
                    
                    // Handle Friday prayer
                    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
                    let flags = NSCalendarUnit.Weekday
                    let components = calendar?.components(flags, fromDate: date)
                    if components?.weekday == 6 {
                        self.name = "Jumuah"
                    }
                case .Asr:
                    self.abbr = "ASR"
                    self.isFard = true
                case .Maghrib:
                    self.abbr = "MGB"
                    self.isFard = true
                case .Isha:
                    self.abbr = "ISH"
                    self.isFard = true
                default: break
                }
        }
        
        // Convert float time to the given format (see timeFormats)
        public func getFormattedTime(var format: String? = nil, var suffixes: [String]? = nil) -> String {
            format = format ?? timeFormat
            suffixes = suffixes ?? timeSuffixes
            
            if time == 0 {
                return invalidTime
            }
            
            if format == "Float" {
                return "\(time)"
            }
            
            let timeComponents = PrayTimes.getTimeComponents(time)
            let hours = timeComponents[0]
            let minutes = timeComponents[1]
            
            let suffix = format == "12h" && suffixes!.count > 0 ? (hours < 12 ? suffixes![0] : suffixes![1]) : ""
            let hour = format == "24h" ? PrayTimes.twoDigitsFormat(hours) : "\(Int((hours + 12 - 1) % 12 + 1))"
            
            let output = hour + ":" + PrayTimes.twoDigitsFormat(minutes)
                + (suffix != "" ? " " + suffix : "")
            
            return output
        }
    }
    
    public struct PrayerResultSeries {
        public var date: NSDate
        public var prayers: [PrayerResult]
        
        public init(date: NSDate, prayers: [PrayerResult]) {
            self.date = date
            self.prayers = prayers
        }
    }
    
    //------------------------ Constants --------------------------
    
    // Calculation Methods
    let methods = [
        "MWL": PrayerMethod("Muslim World League", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 18.0),
            AdjustmentParam(time: .Isha, type: .Degree, value: 17.0)
            ]),
        "ISNA": PrayerMethod("Islamic Society of North America (ISNA)", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 15.0),
            AdjustmentParam(time: .Isha, type: .Degree, value: 15.0)
            ]),
        "Egypt": PrayerMethod("Egyptian General Authority of Survey", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 19.5),
            AdjustmentParam(time: .Isha, type: .Degree, value: 17.5)
            ]),
        "Makkah": PrayerMethod("Umm Al-Qura University, Makkah", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 18.5), // Fajr was 19 degrees before 1430 hijri
            AdjustmentParam(time: .Isha, type: .Minute, value: 90.0)
            ]),
        "Karachi": PrayerMethod("University of Islamic Sciences, Karachi", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 18.0),
            AdjustmentParam(time: .Isha, type: .Degree, value: 18.0)
            ]),
        "Tehran": PrayerMethod("Institute of Geophysics, University of Tehran", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 17.7),
            AdjustmentParam(time: .Maghrib, type: .Degree, value: 4.5),
            AdjustmentParam(time: .Isha, type: .Degree, value: 14.0),
            AdjustmentParam(time: .Midnight, type: .Method, value: AdjustmentMethod.Jafari)
            ]),
        "Jafari": PrayerMethod("Shia Ithna-Ashari, Leva Institute, Qum", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 16.0),
            AdjustmentParam(time: .Maghrib, type: .Degree, value: 4.0),
            AdjustmentParam(time: .Isha, type: .Degree, value: 14.0),
            AdjustmentParam(time: .Midnight, type: .Method, value: AdjustmentMethod.Jafari)
            ]),
        "UOIF": PrayerMethod("Union of Islamic Organizations of France", [
            AdjustmentParam(time: .Fajr, type: .Degree, value: 12.0),
            AdjustmentParam(time: .Isha, type: .Degree, value: 12.0)
            ])
    ]
    
    //---------------------- Default Settings --------------------
    
    static let defaultParams = [
        AdjustmentParam(
            time: .Maghrib,
            type: .Minute,
            value: 0.0
        ),
        AdjustmentParam(
            time: .Midnight,
            type: .Method,
            value: AdjustmentMethod.Standard
        )
    ]
    
    static let defaultSettings = [
        AdjustmentParam(time: .Imsak, type: .Minute, value: 10.0),
        AdjustmentParam(time: .Dhuhr, type: .Minute, value: 0.0),
        AdjustmentParam(time: .Asr, type: .Method, value: AdjustmentMethod.Standard)
    ]
    
    static let defaultTimes: [TimeName: Double] = [
        .Imsak: 5.0,
        .Fajr: 5.0,
        .Sunrise: 6.0,
        .Dhuhr: 12.0,
        .Asr: 13.0,
        .Sunset: 18.0,
        .Maghrib: 18.0,
        .Isha: 18.0
    ]
    
    // Do not change anything here; use adjust method instead
    var calcMethod = "MWL"
    var highLats = ElavationMethod.NightMiddle
    var settings = defaultSettings
    
    public var timeFormat = "12h"
    public var timeSuffixes = ["am", "pm"]
    
    var timeZone =  Double(0)
    var jDate =  Double(0)
    var invalidTime =  "-----"
    
    var lat = Double(0)
    var lng = Double(0)
    var elv = Double(0)
    
    var numIterations = 1
    var offset: [TimeName: Double] = [
        .Imsak: 0.0,
        .Fajr: 0.0,
        .Sunrise: 0.0,
        .Dhuhr: 0.0,
        .Asr: 0.0,
        .Sunset: 0.0,
        .Maghrib: 0.0,
        .Isha: 0.0,
        .Midnight: 0.0
    ]
    
    //---------------------- Initialization -----------------------
    
    public init(method: String? = nil, juristic: AdjustmentMethod? = nil) {
        setMethod(method ?? calcMethod)
        
        // Update juristic method if applicable
        if let j = juristic {
            //for item in settings {
            for (index, item) in settings.enumerate() {
                if item.type == .Method {
                    settings[index].value = j
                }
            }
        }
    }
    
    //-------------------- Interface Functions --------------------
    
    public mutating func setMethod(method: String) {
        // Reset settings
        settings = PrayTimes.defaultSettings
        
        // Get prayer method for adjustments
        if let item = methods[method] {
            calcMethod = method
            adjust(item.params)
        } else {
            adjust(methods[calcMethod]!.params)
        }
    }
    
    public mutating func adjust(params: [AdjustmentParam]) {
        for item in params {
            settings = settings.filter { $0.time != item.time } // Remove duplicate
            settings.append(item)
        }
    }
    
    public mutating func tune(timeOffsets: [TimeName: Double]) {
        for item in timeOffsets {
            offset[item.0] = item.1;
        }
    }
    
    public func getMethod() -> String {
        return calcMethod
    }
    
    public func getSettings() -> [AdjustmentParam] {
        return settings
    }
    
    public func getOffsets() -> [TimeName: Double] {
        return offset
    }
    
    public func getDefaults() -> [String: PrayerMethod] {
        return methods
    }
    
    public func getSetting(time: TimeName) -> AdjustmentParam! {
        return settings.filter { $0.time == time }.first
    }
    
    public func getSettingValue(time: TimeName) -> Double {
        let setting = getSetting(time)
        return setting.type == .Minute || setting.type == .Degree
            ? getSetting(time).value as! Double : 0.0
    }
    
    // Get prayer times for a given date
    public mutating func getTimes(
        coordinates: [Double],
        date: NSDate = NSDate(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        onlyEssentials: Bool = false,
        completionHandler: (prayers: [PrayerResult]) -> Void) {
            lat = coordinates[0]
            lng = coordinates[1]
            elv = coordinates.count > 2 ? coordinates[2] : 0
            jDate = PrayTimes.getJulian(date) - lng / (15 * 24)
            timeFormat = format ?? timeFormat
            
            let deferredTask: () -> Void = {
                var result = self.computeTimes().map {
                    PrayerResult($0.0, $0.1,
                        date: date,
                        requestDate: date,
                        coordinates: coordinates,
                        timeZone: self.timeZone,
                        timeFormat: self.timeFormat,
                        timeSuffixes: self.timeSuffixes)
                    }.sort {
                        $0.time < $1.time
                }
                
                // Assign next and current prayers
                if let nextType = result.filter({ $0.date.compare(date) == .OrderedDescending
                    && ($0.isFard || $0.type == .Sunrise) }).first?.type {
                        let currentType = PrayTimes.getPreviousPrayer(nextType)
                        
                        for (index, item) in result.enumerate() {
                            switch item.type {
                            case currentType:
                                result[index].isCurrent = true
                            case nextType:
                                result[index].isNext = true
                            default: break
                            }
                        }
                } else {
                    // Handle current and next prayers if times fall tomorrow
                    for (index, item) in result.enumerate() {
                        switch item.type {
                        case .Fajr:
                            result[index].isNext = true
                        case .Isha:
                            result[index].isCurrent = true
                        default: break
                        }
                    }
                }
                
                // Increment dates for past prayers if applicable
                for (index, item) in result.enumerate() {
                    if item.date.compare(date) == .OrderedAscending {
                        if !item.isCurrent {
                            result[index].date = NSCalendar.currentCalendar()
                                .dateByAddingUnit(.Day,
                                    value: 1,
                                    toDate: result[index].date,
                                    options: NSCalendarOptions(rawValue: 0)
                                )!
                        }
                    } else {
                        // Move Isha to previous day if middle of the night
                        if item.isCurrent && item.type == .Isha {
                            result[index].date = NSCalendar.currentCalendar()
                                .dateByAddingUnit(.Day,
                                    value: -1,
                                    toDate: result[index].date,
                                    options: NSCalendarOptions(rawValue: 0)
                                )!
                        }
                    }
                }
                
                // Process callback
                completionHandler(prayers: onlyEssentials
                    ? result.filter { $0.isFard || $0.type == .Sunrise }
                    : result)
            }
            
            // Calculate timezone
            if let tz = timeZone {
                self.timeZone = tz
                
                // Factor in daylight if applicable
                if dst {
                    self.timeZone++
                }
                
                deferredTask()
            } else if isLocalCoords {
                // Get local time zone of device
                self.timeZone = Double(NSTimeZone.localTimeZone().secondsFromGMT) / 60.0 / 60.0
                
                deferredTask()
            } else {
                // If no timezone given or coords are not local, we can retrive automatically from remote web service
                let url = "https://maps.googleapis.com/maps/api/timezone/json?location=\(lat),\(lng)&timestamp=\(date.timeIntervalSince1970)"
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: url)!) {
                    (data, response, error) in
                    
                    if (error == nil) {
                        let err: NSError? = nil
                        let jsonData = (try! NSJSONSerialization.JSONObjectWithData(data!,
                            options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
                        
                        if (err == nil && (jsonData["status"] as? String) == "OK") {
                            self.timeZone = jsonData["rawOffset"] as! Double / 60.0 / 60.0
                            
                            // Factor in daylight if applicable
                            if dst {
                                self.timeZone += (jsonData["dstOffset"] as! Double / 60.0 / 60.0)
                            }
                            
                            deferredTask()
                        } else {
                            print("JSON Error")
                        }
                    } else {
                        print(error!.localizedDescription)
                    }
                    }.resume()
            }
    }
    
    public mutating func getTimeSeries(
        coordinates: [Double],
        endDate: NSDate,
        startDate: NSDate = NSDate(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        onlyEssentials: Bool = false,
        completionHandler: (series: [PrayerResultSeries]) -> Void) {
            var series: [PrayerResultSeries] = []
            
            getTimeline(coordinates,
                endDate: endDate,
                startDate: startDate,
                timeZone: timeZone,
                dst: dst,
                dstOffset: dstOffset,
                format: format,
                isLocalCoords: isLocalCoords,
                onlyEssentials: true,
                completionPerDate: { date, prayers in
                    series.append(PrayerResultSeries(date: date, prayers: prayers))
                }) { _ in completionHandler(series: series) }
    }
    
    public mutating func getTimeline(
        coordinates: [Double],
        endDate: NSDate,
        startDate: NSDate = NSDate(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        onlyEssentials: Bool = false,
        completionPerDate: ((date: NSDate, prayers: [PrayerResult]) -> Void)? = nil,
        completionHandler: (prayers: [PrayerResult]) -> Void) {
            precondition(startDate.compare(endDate) == .OrderedAscending,
                "Start date must be before end date!")
            
            var startOfEndDate = NSCalendar.currentCalendar().startOfDayForDate(endDate)
            var allPrayers: [PrayerResult] = []
            
            func repeatTask(date: NSDate) {
                // Retrieve prayer times for day
                getTimes(coordinates,
                    date: date,
                    timeZone: timeZone,
                    dst: dst,
                    dstOffset: dstOffset,
                    format: format,
                    isLocalCoords: isLocalCoords,
                    onlyEssentials: onlyEssentials) { prayers in
                        allPrayers += prayers
                        
                        // Process callback per date if applicable
                        if let completionPerDate = completionPerDate {
                            completionPerDate(date: date, prayers: prayers)
                        }
                        
                        // Process callback and exit if range complete
                        if date.compare(startOfEndDate) == .OrderedSame {
                            // Process callback
                            completionHandler(prayers: allPrayers.sort {
                                $0.date.compare($1.date) == .OrderedAscending
                                }.filter { // Trim results
                                    return $0.date.compare(startDate) == .OrderedDescending
                                        && $0.date.compare(endDate) == .OrderedAscending
                                })
                            return
                        } else {
                            repeatTask(NSCalendar.currentCalendar()
                                .dateByAddingUnit(.Day,
                                    value: 1,
                                    toDate: date,
                                    options: NSCalendarOptions(rawValue: 0)
                                )!)
                        }
                }
            }
            
            repeatTask(NSCalendar.currentCalendar()
                .startOfDayForDate(startDate))
    }
    
    //---------------------- Compute Prayer Times -----------------------
    
    // Compute prayer times
    func computeTimes() -> [TimeName: Double] {
        var times = computePrayerTimes(PrayTimes.defaultTimes)
        
        times = adjustTimes(times)
        
        // Add midnight time
        let midnight = getSetting(.Midnight);
        times[.Midnight] = midnight.type == .Method
            && (midnight.value as! AdjustmentMethod) == .Jafari
            ? times[.Sunset]! + PrayTimes.timeDiff(times[.Sunset], times[.Fajr]) / 2
            : times[.Sunset]! + PrayTimes.timeDiff(times[.Sunset], times[.Sunrise]) / 2
        
        times = tuneTimes(times);
        
        return times
    }
    
    // Compute prayer times at given julian date
    func computePrayerTimes(var times: [TimeName: Double]) -> [TimeName: Double] {
        times = PrayTimes.dayPortion(times)
        
        let imsak = sunAngleTime(getSettingValue(.Imsak),
            time: times[.Imsak],
            direction: "ccw")
        
        let fajr = sunAngleTime(getSettingValue(.Fajr),
            time: times[.Fajr],
            direction: "ccw")
        
        let sunrise = sunAngleTime(riseSetAngle(),
            time: times[.Sunrise],
            direction: "ccw")
        
        let dhuhr = midDay(times[.Dhuhr])
        
        let asr = asrTime(times[.Asr])
        
        let sunset = sunAngleTime(riseSetAngle(),
            time: times[.Sunset])
        
        let maghrib = sunAngleTime(getSettingValue(.Maghrib),
            time: times[.Maghrib])
        
        let isha = sunAngleTime(getSettingValue(.Isha),
            time: times[.Isha])
        
        return [
            .Imsak: imsak,
            .Fajr: fajr,
            .Sunrise: sunrise,
            .Dhuhr: dhuhr,
            .Asr: asr,
            .Sunset: sunset,
            .Maghrib: maghrib,
            .Isha: isha
        ]
    }
    
    //---------------------- Calculation Functions -----------------------
    
    // Compute mid-day time
    func midDay(time: Double!) -> Double {
        let eqt = PrayTimes.sunPosition(jDate + time).equation
        let noon = PrayTimes.fixHour(12.0 - eqt)
        return noon
    }
    
    // Compute the time at which sun reaches a specific angle below horizon
    func sunAngleTime(angle: Double!, time: Double!, direction: String? = nil) -> Double {
        let decl = PrayTimes.sunPosition(jDate + time).declination
        let noon = midDay(time)
        
        let t = 1 / 15 * PrayTimes.arccos(
            (-PrayTimes.sin(angle) - PrayTimes.sin(decl) * PrayTimes.sin(lat))
                / (PrayTimes.cos(decl) * PrayTimes.cos(lat)))
        
        return noon + (direction == "ccw" ? -t : t)
    }
    
    // Get sun angle for sunset/sunrise
    func riseSetAngle() -> Double {
        //var earthRad = 6371009; // in meters
        //var angle = DMath.arccos(earthRad/(earthRad+ elv));
        let angle = 0.0347 * sqrt(elv) // an approximation
        return 0.833 + angle
    }
    
    // Adjust times
    func adjustTimes(var times: [TimeName: Double]) -> [TimeName: Double] {
        for item in times {
            times[item.0] = times[item.0]!
                + (Double(timeZone) - lng / 15)
        }
        
        if highLats != ElavationMethod.None {
            times = adjustHighLats(times);
        }
        
        let imsak = getSetting(.Imsak)
        if (imsak.type == .Minute) {
            times[.Imsak] = times[.Fajr]!
                - (imsak.value as! Double) / 60.0
        }
        
        let maghrib = getSetting(.Maghrib)
        if (maghrib.type == .Minute) {
            times[.Maghrib] = times[.Sunset]!
                + (maghrib.value as! Double) / 60.0
        }
        
        let isha = getSetting(.Isha)
        if (isha.type == .Minute) {
            times[.Isha] = times[.Maghrib]!
                + (isha.value as! Double) / 60.0
        }
        
        times[.Dhuhr] = times[.Dhuhr]!
            + getSettingValue(.Dhuhr) / 60.0
        
        return times;
    }
    
    // Adjust times for locations in higher latitudes
    func adjustHighLats(var times: [TimeName: Double]) -> [TimeName: Double] {
        let nightTime = PrayTimes.timeDiff(times[.Sunset], times[.Sunrise])
        
        times[.Imsak] = adjustHLTime(times[.Imsak],
            base: times[.Sunrise],
            angle: getSettingValue(.Imsak),
            night: nightTime,
            direction: "ccw")
        
        times[.Fajr]  = adjustHLTime(times[.Fajr],
            base: times[.Sunrise],
            angle: getSettingValue(.Fajr),
            night: nightTime,
            direction: "ccw")
        
        times[.Isha]  = adjustHLTime(times[.Isha],
            base: times[.Sunset],
            angle: getSettingValue(.Isha),
            night: nightTime)
        
        times[.Maghrib] = adjustHLTime(times[.Maghrib],
            base: times[.Sunset],
            angle: getSettingValue(.Maghrib),
            night: nightTime)
        
        return times;
    }
    
    // Adjust times for locations in higher latitudes
    func adjustHLTime(var time: Double!, base: Double!, angle: Double!, night: Double!, direction: String? = nil) -> Double {
        let portion = nightPortion(angle, night)
        
        let diff = direction == "ccw"
            ? PrayTimes.timeDiff(time, base)
            : PrayTimes.timeDiff(base, time)
        
        if (time.isNaN || diff > portion) {
            time = base + (direction == "ccw" ? -portion : portion)
        }
        
        return time
    }
    
    // The night portion used for adjusting times in higher latitudes
    func nightPortion(angle: Double!, _ night: Double!) -> Double {
        var portion = 1.0 / 2.0 // MidNight
        
        if highLats == ElavationMethod.AngleBased {
            portion = 1.0 / 60.0 * angle;
        }
        
        if highLats == ElavationMethod.OneSeventh {
            portion = 1.0 / 7.0;
        }
        
        return portion * night;
    }
    
    // Apply offsets to the times
    func tuneTimes(var times: [TimeName: Double]) -> [TimeName: Double] {
        for item in times {
            times[item.0] = times[item.0]! + offset[item.0]! / 60.0
        }
        
        return times
    }
    
    // Compute asr time
    func asrTime(time: Double!) -> Double {
        let param = getSetting(.Asr)
        let factor = asrFactor(param)
        let decl = PrayTimes.sunPosition(jDate + time).declination
        let angle = -PrayTimes.arccot(factor + PrayTimes.tan(abs(lat - decl)))
        return sunAngleTime(angle, time: time)
    }
    
    // Get asr shadow factor
    func asrFactor(asrParam: AdjustmentParam) -> Double {
        if asrParam.type == .Method {
            let method = asrParam.value as! AdjustmentMethod
            
            return method == .Standard ? 1
                : method == .Hanafi ? 2
                : getSettingValue(asrParam.time)
        }
        
        return getSettingValue(asrParam.time);
    }
    
    //---------------------- Static Functions -----------------------
    
    // Convert hours to day portions
    static func dayPortion(var times: [TimeName: Double]) -> [TimeName: Double] {
        for item in times {
            times[item.0] = times[item.0]! / 24.0
        }
        
        return times
    }
    
    // Compute declination angle of sun and equation of time
    // Ref: http://aa.usno.navy.mil/faq/docs/SunApprox.php
    static func sunPosition(jd: Double) -> (declination: Double, equation: Double) {
        let D = jd - 2451545.0
        let g = fixAngle(357.529 + 0.98560028 * D)
        let q = fixAngle(280.459 + 0.98564736 * D)
        let L = fixAngle(q + 1.915 * sin(g) + 0.020 * sin(2 * g))
        let e = 23.439 - 0.00000036 * D
        
        let RA = arctan2(cos(e) * sin(L), cos(L)) / 15.0
        let eqt = q / 15.0 - fixHour(RA)
        let decl = arcsin(sin(e) * sin(L))
        
        return (declination: decl, equation: eqt)
    }
    
    // Convert Gregorian date to Julian day
    // Ref: Astronomical Algorithms by Jean Meeus
    static func getJulian(date: NSDate) -> Double {
        let flags: NSCalendarUnit = [.Day, .Month, .Year]
        let components = NSCalendar.currentCalendar().components(flags, fromDate: date)
        
        if components.month <= 2 {
            components.year -= 1
            components.month += 12
        }
        
        let A = floor(Double(components.year) / Double(100));
        let B = 2 - A + floor(A / Double(4));
        let C = floor(Double(365.25) * Double(components.year + 4716))
        let D = floor(Double(30.6001) * Double(components.month + 1))
        let E = Double(components.day) + B - 1524.5
        
        let JD = C + D + E
        
        return JD
    }
    
    //----------------- Degree-Based Math Functions -------------------
    
    static func dtr(d: Double) -> Double { return (d * M_PI) / 180.0 }
    static func rtd(r: Double) -> Double { return (r * 180.0) / M_PI }
    
    static func sin(d: Double) -> Double { return Darwin.sin(dtr(d)) }
    static func cos(d: Double) -> Double { return Darwin.cos(dtr(d)) }
    static func tan(d: Double) -> Double { return Darwin.tan(dtr(d)) }
    
    static func arcsin(d: Double) -> Double { return rtd(Darwin.asin(d)) }
    static func arccos(d: Double) -> Double { return rtd(Darwin.acos(d)) }
    static func arctan(d: Double) -> Double { return rtd(Darwin.atan(d)) }
    
    static func arccot(x: Double) -> Double { return rtd(Darwin.atan(1 / x)) }
    static func arctan2(y: Double, _ x: Double) -> Double { return rtd(Darwin.atan2(y, x)) }
    
    static func fixAngle(a: Double) -> Double { return fix(a, 360.0) }
    static func fixHour(a: Double) -> Double { return fix(a, 24.0 ) }
    
    static func fix(a: Double, _ b: Double) -> Double {
        let a = a - b * (floor(a / b))
        return a < 0 ? a + b : a
    }
    
    //---------------------- Misc Static Functions -----------------------
    
    // Compute the difference between two times
    static func timeDiff(time1: Double!, _ time2: Double!) -> Double {
        return fixHour(time2 - time1);
    }
    
    static func timeToDecimal(date: NSDate = NSDate()) -> Double {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour, .Minute],
            fromDate: date)
        let hour = components.hour
        let minutes = components.minute
        return Double(hour) + (Double(minutes) / 60.0)
    }
    
    // Add a leading 0 if necessary
    static func twoDigitsFormat(num: Int!) -> String {
        return num < 10 ? "0\(num)" : "\(num)"
    }
    
    static func getTimeComponents(time: Double) -> [Int] {
        let roundedTime = fixHour(time + 0.5 / 60) // Add 0.5 minutes to round
        var hours = floor(roundedTime)
        var minutes = round((roundedTime - hours) * 60.0)
        
        // Handle scenario when minutes is rounded to 60
        if minutes > 59 {
            hours++
            minutes = 0
        }
        
        return [Int(hours), Int(minutes)]
    }
    
    public static func getPreviousPrayer(time: PrayTimes.TimeName) -> PrayTimes.TimeName {
        switch time {
        case .Fajr: return .Isha
        case .Sunrise: return .Fajr
        case .Dhuhr: return .Sunrise
        case .Asr: return .Dhuhr
        case .Maghrib: return .Asr
        case .Isha: return .Maghrib
        default: return .Fajr
        }
    }
    
    public static func getNextPrayer(time: PrayTimes.TimeName) -> PrayTimes.TimeName {
        switch time {
        case .Fajr: return .Sunrise
        case .Sunrise: return .Dhuhr
        case .Dhuhr: return .Asr
        case .Asr: return .Maghrib
        case .Maghrib: return .Isha
        case .Isha: return .Fajr
        default: return .Isha
        }
    }
    
}
