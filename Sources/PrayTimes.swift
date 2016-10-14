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
        case imsak, fajr, sunrise, dhuhr, asr, sunset, maghrib, isha, midnight
        
        static let names = [
            imsak: "Imsak",
            fajr: "Fajr",
            sunrise: "Sunrise",
            dhuhr: "Dhuhr",
            asr: "Asr",
            sunset: "Sunset",
            maghrib: "Maghrib",
            isha: "Isha",
            midnight: "Midnight"
        ]
        
        // http://natashatherobot.com/swift-enums-tableviews/
        public func getName() -> String {
            return TimeName.names[self] ?? ""
        }
    }
    
    public enum AdjustmentType {
        case degree, minute, method, factor
    }
    
    public enum AdjustmentMethod: String {
        case Standard, Hanafi, Jafari
    }
    
    public enum ElavationMethod: String {
        case None, NightMiddle, OneSeventh, AngleBased
    }
    
    //------------------------ Structs/Classes --------------------------
    
    public struct AdjustmentParam {
        var time: TimeName
        var type: AdjustmentType
        var value: Any?
        
        public init(time: TimeName, type: AdjustmentType, value: Any?) {
            self.time = time
            self.type = type
            self.value = value
        }
    }
    
    public struct PrayerMethod {
        var description: String
        var params = [AdjustmentParam]()
        var elavation: ElavationMethod?
        
        public init(_ description: String, _ params: [AdjustmentParam], elavation: ElavationMethod? = nil) {
            self.description = description
            self.params = params
            self.elavation = elavation
            
            // Add default params if applicable
            for item in PrayTimes.defaultParams {
                if !self.params.contains(where: { $0.time == item.time }) {
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
        public var date: Date
        public var requestDate: Date
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
            date: Date = Date(),
            requestDate: Date = Date(),
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
                    self.date = Calendar.current
                        .date(byAdding: .day,
                            value: 1,
                            to: self.date
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
                    self.date = Calendar.current
                        .date(byAdding: .day,
                            value: 1,
                            to: self.date
                        )!
                    
                    timeComponents[0] -= 24
                }
                
                self.date = Calendar.current
                    .date(bySettingHour: timeComponents[0],
                        minute: timeComponents[1],
                        second: 0,
                        of: self.date
                    )!
                
                // Handle specific prayers
                switch (type) {
                case .imsak:
                    self.abbr = "IMK"
                case .fajr:
                    self.abbr = "FJR"
                    self.isFard = true
                case .sunrise:
                    self.abbr = "SHK"
                case .dhuhr:
                    self.abbr = "DHR"
                    self.isFard = true
                    
                    // Handle Friday prayer
                    let calendar = Calendar(identifier: .gregorian)
                    let flags: Set<Calendar.Component> = [.weekday]
                    let components = calendar.dateComponents(flags, from: date)
                    if components.weekday == 6 {
                        self.name = "Jumuah"
                    }
                case .asr:
                    self.abbr = "ASR"
                    self.isFard = true
                case .maghrib:
                    self.abbr = "MGB"
                    self.isFard = true
                case .isha:
                    self.abbr = "ISH"
                    self.isFard = true
                case .midnight:
                    self.abbr = "MID"
                default: break
                }
        }
        
        // Convert float time to the given format (see timeFormats)
        public func getFormattedTime(_ format: String? = nil, suffixes: [String]? = nil) -> String {
            let format = format ?? timeFormat
            var suffixes = suffixes ?? timeSuffixes
            
            if time == 0 {
                return invalidTime
            }
            
            if format == "Float" {
                return "\(time)"
            }
            
            let timeComponents = PrayTimes.getTimeComponents(time)
            let hours = timeComponents[0]
            let minutes = timeComponents[1]
            
            let suffix = format == "12h" && suffixes.count > 0 ? (hours < 12 ? suffixes[0] : suffixes[1]) : ""
            let hour = format == "24h" ? PrayTimes.twoDigitsFormat(hours) : "\(Int((hours + 12 - 1) % 12 + 1))"
            
            let output = hour + ":" + PrayTimes.twoDigitsFormat(minutes)
                + (suffix != "" ? " " + suffix : "")
            
            return output
        }
    }
    
    public struct PrayerResultSeries {
        public var date: Date
        public var prayers: [PrayerResult]
        
        public init(date: Date, prayers: [PrayerResult]) {
            self.date = date
            self.prayers = prayers
        }
    }
    
    //------------------------ Constants --------------------------
    
    // Calculation Methods
    let methods = [
        "MWL": PrayerMethod("Muslim World League", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .degree, value: 17.0)
            ]),
        "ISNA": PrayerMethod("Islamic Society of North America (ISNA)", [
            AdjustmentParam(time: .fajr, type: .degree, value: 15.0),
            AdjustmentParam(time: .isha, type: .degree, value: 15.0)
            ]),
        "Egypt": PrayerMethod("Egyptian General Authority of Survey", [
            AdjustmentParam(time: .fajr, type: .degree, value: 19.5),
            AdjustmentParam(time: .isha, type: .degree, value: 17.5)
            ]),
        "Makkah": PrayerMethod("Umm Al-Qura University, Makkah", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.5), // Fajr was 19 degrees before 1430 hijri
            AdjustmentParam(time: .isha, type: .minute, value: 90.0)
            ]),
        "Karachi": PrayerMethod("University of Islamic Sciences, Karachi", [
            AdjustmentParam(time: .fajr, type: .degree, value: 18.0),
            AdjustmentParam(time: .isha, type: .degree, value: 18.0)
            ]),
        "Tehran": PrayerMethod("Institute of Geophysics, University of Tehran", [
            AdjustmentParam(time: .fajr, type: .degree, value: 17.7),
            AdjustmentParam(time: .maghrib, type: .degree, value: 4.5),
            AdjustmentParam(time: .isha, type: .degree, value: 14.0),
            AdjustmentParam(time: .midnight, type: .method, value: AdjustmentMethod.Jafari)
            ]),
        "Jafari": PrayerMethod("Shia Ithna-Ashari, Leva Institute, Qum", [
            AdjustmentParam(time: .fajr, type: .degree, value: 16.0),
            AdjustmentParam(time: .maghrib, type: .degree, value: 4.0),
            AdjustmentParam(time: .isha, type: .degree, value: 14.0),
            AdjustmentParam(time: .midnight, type: .method, value: AdjustmentMethod.Jafari)
            ]),
        "UIOF": PrayerMethod("Union of Islamic Organizations of France", [
            AdjustmentParam(time: .fajr, type: .degree, value: 12.0),
            AdjustmentParam(time: .isha, type: .degree, value: 12.0)
            ])
    ]
    
    //---------------------- Default Settings --------------------
    
    static let defaultParams = [
        AdjustmentParam(
            time: .maghrib,
            type: .minute,
            value: 0.0
        ),
        AdjustmentParam(
            time: .midnight,
            type: .method,
            value: AdjustmentMethod.Standard
        )
    ]
    
    static let defaultSettings = [
        AdjustmentParam(time: .imsak, type: .minute, value: 10.0),
        AdjustmentParam(time: .dhuhr, type: .minute, value: 0.0),
        AdjustmentParam(time: .asr, type: .method, value: AdjustmentMethod.Standard)
    ]
    
    static let defaultTimes: [TimeName: Double] = [
        .imsak: 5.0,
        .fajr: 5.0,
        .sunrise: 6.0,
        .dhuhr: 12.0,
        .asr: 13.0,
        .sunset: 18.0,
        .maghrib: 18.0,
        .isha: 18.0
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
        .imsak: 0.0,
        .fajr: 0.0,
        .sunrise: 0.0,
        .dhuhr: 0.0,
        .asr: 0.0,
        .sunset: 0.0,
        .maghrib: 0.0,
        .isha: 0.0,
        .midnight: 0.0
    ]
    
    //---------------------- Initialization -----------------------
    
    public init(method: String? = nil, juristic: AdjustmentMethod? = nil) {
        setMethod(method ?? calcMethod)
        
        // Update juristic method if applicable
        if let j = juristic {
            //for item in settings {
            for (index, item) in settings.enumerated() {
                if item.type == .method {
                    settings[index].value = j
                }
            }
        }
    }
    
    public init(method: PrayerMethod, juristic: AdjustmentMethod? = nil) {
        // Reset settings
        settings = PrayTimes.defaultSettings
        
        // Get prayer method for adjustments
        calcMethod = method.description
        adjust(method.params)
        
        if let elavation = method.elavation {
            highLats = elavation
        }
        
        // Update juristic method if applicable
        if let j = juristic {
            //for item in settings {
            for (index, item) in settings.enumerated() {
                if item.type == .method {
                    settings[index].value = j
                }
            }
        }
    }
    
    //-------------------- Interface Functions --------------------
    
    public mutating func setMethod(_ method: String) {
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
    
    public mutating func adjust(_ params: [AdjustmentParam]) {
        for item in params {
            settings = settings.filter { $0.time != item.time } // Remove duplicate
            settings.append(item)
        }
    }
    
    public mutating func tune(_ timeOffsets: [TimeName: Double]) {
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
    
    public func getSetting(_ time: TimeName) -> AdjustmentParam! {
        return settings.filter { $0.time == time }.first
    }
    
    public func getSettingValue(_ time: TimeName) -> Double {
        let setting = getSetting(time)
        return setting!.type == .minute || setting!.type == .degree
            ? getSetting(time).value as! Double : 0.0
    }
    
    // Get prayer times for a given date
    public mutating func getTimes(for coordinates: [Double],
        date: Date = Date(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        onlyEssentials: Bool = false,
        handler: @escaping ([PrayerResult]) -> Void) {
            lat = coordinates[0]
            lng = coordinates[1]
            elv = coordinates.count > 2 ? coordinates[2] : 0
            jDate = PrayTimes.getJulian(for: date) - lng / (15 * 24)
            timeFormat = format ?? timeFormat
        
            func deferredTask(with timeZone: Double? = nil) {
                if let timeZone = timeZone {
                    self.timeZone = timeZone
                }
            
                var result = self.computeTimes().map {
                    PrayerResult($0.0, $0.1,
                        date: date,
                        requestDate: date,
                        coordinates: coordinates,
                        timeZone: self.timeZone,
                        timeFormat: self.timeFormat,
                        timeSuffixes: self.timeSuffixes)
                    }.sorted {
                        $0.time < $1.time
                }
                
                // Assign next and current prayers
                if let nextType = result.filter({ $0.date.compare(date) == .orderedDescending
                    && ($0.isFard || $0.type == .sunrise) }).first?.type {
                        let currentType = PrayTimes.getPreviousPrayer(nextType)
                        
                        for (index, item) in result.enumerated() {
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
                    for (index, item) in result.enumerated() {
                        switch item.type {
                        case .fajr:
                            result[index].isNext = true
                        case .isha:
                            result[index].isCurrent = true
                        default: break
                        }
                    }
                }
                
                // Increment dates for past prayers if applicable
                for (index, item) in result.enumerated() {
                    if item.date.compare(date) == .orderedAscending {
                        if !item.isCurrent {
                            result[index].date = Calendar.current
                                .date(byAdding: .day,
                                    value: 1,
                                    to: result[index].date
                                )!
                        }
                    } else {
                        // Move Isha to previous day if middle of the night
                        if item.isCurrent && item.type == .isha {
                            result[index].date = Calendar.current
                                .date(byAdding: .day,
                                    value: -1,
                                    to: result[index].date
                                )!
                        }
                    }
                }
                
                // Process callback
                handler(onlyEssentials
                    ? result.filter { ($0.isFard || $0.type == .sunrise) && $0.type != .sunset }
                    : result.filter { $0.type != .sunset })
            }
            
            // Calculate timezone
            if let tz = timeZone {
                self.timeZone = tz
                
                // Factor in daylight if applicable
                if dst {
                    self.timeZone += 1
                }
                
                deferredTask()
            } else if isLocalCoords {
                // Get local time zone of device
                self.timeZone = Double(TimeZone.ReferenceType.local.secondsFromGMT()) / 60.0 / 60.0
                
                deferredTask()
            } else {
                // If no timezone given or coords are not local, we can retrive automatically from remote web service
                let url = "https://maps.googleapis.com/maps/api/timezone/json?location=\(lat),\(lng)&timestamp=\(date.timeIntervalSince1970)"
                
                URLSession.shared.dataTask(with: URL(string: url)!) {
                    (data, response, error) in
                    
                    if (error == nil) {
                        let err: NSError? = nil
                        let jsonData = (try! JSONSerialization.jsonObject(with: data!,
                            options: JSONSerialization.ReadingOptions.mutableContainers)) as! NSDictionary
                        
                        if (err == nil && (jsonData["status"] as? String) == "OK") {
                            var timeZone = jsonData["rawOffset"] as! Double / 60.0 / 60.0
                            
                            // Factor in daylight if applicable
                            if dst {
                                timeZone += (jsonData["dstOffset"] as! Double / 60.0 / 60.0)
                            }
                            
                            deferredTask(with: timeZone)
                        } else {
                            print("JSON Error")
                        }
                    } else {
                        print(error!.localizedDescription)
                    }
                    }.resume()
            }
    }
    
    public mutating func getTimeSeries(for coordinates: [Double],
        endDate: Date,
        startDate: Date = Date(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        onlyEssentials: Bool = false,
        handler: @escaping ([PrayerResultSeries]) -> Void) {
            var series: [PrayerResultSeries] = []
            
            getTimeline(for: coordinates,
                endDate: endDate,
                startDate: startDate,
                timeZone: timeZone,
                dst: dst,
                dstOffset: dstOffset,
                format: format,
                isLocalCoords: isLocalCoords,
                onlyEssentials: onlyEssentials,
                handlerPerDate: { date, prayers in
                    series.append(PrayerResultSeries(date: date, prayers: prayers))
                }) { _ in handler(series) }
    }
    
    public mutating func getTimeline(for coordinates: [Double],
        endDate: Date,
        startDate: Date = Date(),
        timeZone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        onlyEssentials: Bool = false,
        handlerPerDate: ((Date, [PrayerResult]) -> Void)? = nil,
        handler: @escaping ([PrayerResult]) -> Void) {
            precondition(startDate.compare(endDate) == .orderedAscending,
                "Start date must be before end date!")
            
            var startOfEndDate = Calendar.current.startOfDay(for: endDate)
            var allPrayers: [PrayerResult] = []
            
            func repeatTask(_ date: Date) {
                // Retrieve prayer times for day
                getTimes(for: coordinates,
                    date: date,
                    timeZone: timeZone,
                    dst: dst,
                    dstOffset: dstOffset,
                    format: format,
                    isLocalCoords: isLocalCoords,
                    onlyEssentials: onlyEssentials) { prayers in
                        allPrayers += prayers
                        
                        // Process callback per date if applicable
                        if let handlerPerDate = handlerPerDate {
                            handlerPerDate(date, prayers)
                        }
                        
                        // Process callback and exit if range complete
                        if date.compare(startOfEndDate) == .orderedSame {
                            // Process callback
                            handler(allPrayers.sorted {
                                $0.date.compare($1.date) == .orderedAscending
                                }.filter { // Trim results
                                    return $0.date.compare(startDate) == .orderedDescending
                                        && $0.date.compare(endDate) == .orderedAscending
                                })
                            return
                        } else {
                            repeatTask(Calendar.current
                                .date(byAdding: .day,
                                    value: 1,
                                    to: date
                                )!)
                        }
                }
            }
            
            repeatTask(Calendar.current.startOfDay(for: startDate))
    }
    
    //---------------------- Compute Prayer Times -----------------------
    
    // Compute prayer times
    func computeTimes() -> [TimeName: Double] {
        var times = computePrayerTimes(for: PrayTimes.defaultTimes)
        
        times = adjustTimes(for: times)
        
        // Add midnight time
        let midnight = getSetting(.midnight);
        times[.midnight] = midnight?.type == .method
            && (midnight?.value as! AdjustmentMethod) == .Jafari
            ? times[.sunset]! + PrayTimes.timeDiff(times[.sunset], times[.fajr]) / 2
            : times[.sunset]! + PrayTimes.timeDiff(times[.sunset], times[.sunrise]) / 2
        
        times = tuneTimes(at: times);
        
        return times
    }
    
    // Compute prayer times at given julian date
    func computePrayerTimes(for times: [TimeName: Double]) -> [TimeName: Double] {
        var times = PrayTimes.dayPortion(for: times)
        
        let imsak = sunAngleTime(at: getSettingValue(.imsak),
            time: times[.imsak],
            direction: "ccw")
        
        let fajr = sunAngleTime(at: getSettingValue(.fajr),
            time: times[.fajr],
            direction: "ccw")
        
        let sunrise = sunAngleTime(at: riseSetAngle(),
            time: times[.sunrise],
            direction: "ccw")
        
        let dhuhr = midDay(at: times[.dhuhr])
        
        let asr = asrTime(at: times[.asr])
        
        let sunset = sunAngleTime(at: riseSetAngle(),
            time: times[.sunset])
        
        let maghrib = sunAngleTime(at: getSettingValue(.maghrib),
            time: times[.maghrib])
        
        let isha = sunAngleTime(at: getSettingValue(.isha),
            time: times[.isha])
        
        return [
            .imsak: imsak,
            .fajr: fajr,
            .sunrise: sunrise,
            .dhuhr: dhuhr,
            .asr: asr,
            .sunset: sunset,
            .maghrib: maghrib,
            .isha: isha
        ]
    }
    
    //---------------------- Calculation Functions -----------------------
    
    // Compute mid-day time
    func midDay(at time: Double!) -> Double {
        let eqt = PrayTimes.sunPosition(at: jDate + time).equation
        let noon = PrayTimes.fixHour(12.0 - eqt)
        return noon
    }
    
    // Compute the time at which sun reaches a specific angle below horizon
    func sunAngleTime(at angle: Double!, time: Double!, direction: String? = nil) -> Double {
        let decl = PrayTimes.sunPosition(at: jDate + time).declination
        let noon = midDay(at: time)
        
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
    func adjustTimes(for times: [TimeName: Double]) -> [TimeName: Double] {
        var times = times
        
        for item in times {
            times[item.0] = times[item.0]!
                + (Double(timeZone) - lng / 15)
        }
        
        if highLats != ElavationMethod.None {
            times = adjustHighLats(for: times)
        }
        
        let imsak = getSetting(.imsak)
        if (imsak?.type == .minute) {
            times[.imsak] = times[.fajr]!
                - (imsak?.value as! Double) / 60.0
        }
        
        let maghrib = getSetting(.maghrib)
        if (maghrib?.type == .minute) {
            times[.maghrib] = times[.sunset]!
                + (maghrib?.value as! Double) / 60.0
        }
        
        let isha = getSetting(.isha)
        if (isha?.type == .minute) {
            times[.isha] = times[.maghrib]!
                + (isha?.value as! Double) / 60.0
        }
        
        times[.dhuhr] = times[.dhuhr]!
            + getSettingValue(.dhuhr) / 60.0
        
        return times;
    }
    
    // Adjust times for locations in higher latitudes
    func adjustHighLats(for times: [TimeName: Double]) -> [TimeName: Double] {
        var times = times
        
        let nightTime = PrayTimes.timeDiff(times[.sunset], times[.sunrise])
        
        times[.imsak] = adjustHLTime(for: times[.imsak],
            base: times[.sunrise],
            angle: getSettingValue(.imsak),
            night: nightTime,
            direction: "ccw")
        
        times[.fajr]  = adjustHLTime(for: times[.fajr],
            base: times[.sunrise],
            angle: getSettingValue(.fajr),
            night: nightTime,
            direction: "ccw")
        
        times[.isha]  = adjustHLTime(for: times[.isha],
            base: times[.sunset],
            angle: getSettingValue(.isha),
            night: nightTime)
        
        times[.maghrib] = adjustHLTime(for: times[.maghrib],
            base: times[.sunset],
            angle: getSettingValue(.maghrib),
            night: nightTime)
        
        return times;
    }
    
    // Adjust times for locations in higher latitudes
    func adjustHLTime(for time: Double!, base: Double!, angle: Double!, night: Double!, direction: String? = nil) -> Double {
        var time = time
        
        let portion = nightPortion(at: angle, for: night)
        
        let diff = direction == "ccw"
            ? PrayTimes.timeDiff(time, base)
            : PrayTimes.timeDiff(base, time)
        
        if ((time?.isNaN)! || diff > portion) {
            time = base + (direction == "ccw" ? -portion : portion)
        }
        
        return time!
    }
    
    // The night portion used for adjusting times in higher latitudes
    func nightPortion(at angle: Double!, for night: Double!) -> Double {
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
    func tuneTimes(at times: [TimeName: Double]) -> [TimeName: Double] {
        var times = times
        
        for item in times {
            times[item.0] = times[item.0]! + offset[item.0]! / 60.0
        }
        
        return times
    }
    
    // Compute asr time
    func asrTime(at time: Double!) -> Double {
        let param = getSetting(.asr)
        let factor = asrFactor(at: param!)
        let decl = PrayTimes.sunPosition(at: jDate + time).declination
        let angle = -PrayTimes.arccot(factor + PrayTimes.tan(abs(lat - decl)))
        return sunAngleTime(at: angle, time: time)
    }
    
    // Get asr shadow factor
    func asrFactor(at asrParam: AdjustmentParam) -> Double {
        if asrParam.type == .method {
            let method = asrParam.value as! AdjustmentMethod
            
            return method == .Standard || method == .Jafari ? 1
                : method == .Hanafi ? 2
                : getSettingValue(asrParam.time)
        }
        
        return getSettingValue(asrParam.time);
    }
    
    //---------------------- Static Functions -----------------------
    
    // Convert hours to day portions
    static func dayPortion(for times: [TimeName: Double]) -> [TimeName: Double] {
        var times = times
        
        for item in times {
            times[item.0] = times[item.0]! / 24.0
        }
        
        return times
    }
    
    // Compute declination angle of sun and equation of time
    // Ref: http://aa.usno.navy.mil/faq/docs/SunApprox.php
    static func sunPosition(at jd: Double) -> (declination: Double, equation: Double) {
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
    static func getJulian(for date: Date) -> Double {
        let flags: Set<Calendar.Component> = [.day, .month, .year]
        var components = Calendar.current.dateComponents(flags, from: date)
        
        if components.month! <= 2 {
            components.year! -= 1
            components.month! += 12
        }
        
        let A = floor(Double(components.year!) / Double(100));
        let B = 2 - A + floor(A / Double(4));
        let C = floor(Double(365.25) * Double(components.year! + 4716))
        let D = floor(Double(30.6001) * Double(components.month! + 1))
        let E = Double(components.day!) + B - 1524.5
        
        let JD = C + D + E
        
        return JD
    }
    
    //----------------- Degree-Based Math Functions -------------------
    
    static func dtr(_ d: Double) -> Double { return (d * M_PI) / 180.0 }
    static func rtd(_ r: Double) -> Double { return (r * 180.0) / M_PI }
    
    static func sin(_ d: Double) -> Double { return Darwin.sin(dtr(d)) }
    static func cos(_ d: Double) -> Double { return Darwin.cos(dtr(d)) }
    static func tan(_ d: Double) -> Double { return Darwin.tan(dtr(d)) }
    
    static func arcsin(_ d: Double) -> Double { return rtd(Darwin.asin(d)) }
    static func arccos(_ d: Double) -> Double { return rtd(Darwin.acos(d)) }
    static func arctan(_ d: Double) -> Double { return rtd(Darwin.atan(d)) }
    
    static func arccot(_ x: Double) -> Double { return rtd(Darwin.atan(1 / x)) }
    static func arctan2(_ y: Double, _ x: Double) -> Double { return rtd(Darwin.atan2(y, x)) }
    
    static func fixAngle(_ a: Double) -> Double { return fix(a, 360.0) }
    static func fixHour(_ a: Double) -> Double { return fix(a, 24.0 ) }
    
    static func fix(_ a: Double, _ b: Double) -> Double {
        let a = a - b * (floor(a / b))
        return a < 0 ? a + b : a
    }
    
    //---------------------- Misc Static Functions -----------------------
    
    // Compute the difference between two times
    static func timeDiff(_ time1: Double!, _ time2: Double!) -> Double {
        return fixHour(time2 - time1);
    }
    
    static func timeToDecimal(for date: Date = Date()) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour
        let minutes = components.minute
        return Double(hour!) + (Double(minutes!) / 60.0)
    }
    
    // Add a leading 0 if necessary
    static func twoDigitsFormat(_ num: Int) -> String {
        return num < 10 ? "0\(num)" : "\(num)"
    }
    
    static func getTimeComponents(_ time: Double) -> [Int] {
        let roundedTime = fixHour(time + 0.5 / 60) // Add 0.5 minutes to round
        var hours = floor(roundedTime)
        var minutes = round((roundedTime - hours) * 60.0)
        
        // Handle scenario when minutes is rounded to 60
        if minutes > 59 {
            hours += 1
            minutes = 0
        }
        
        return [Int(hours), Int(minutes)]
    }
    
    public static func getPreviousPrayer(_ time: PrayTimes.TimeName) -> PrayTimes.TimeName {
        switch time {
        case .imsak: return .isha
        case .fajr: return .isha
        case .sunrise: return .fajr
        case .dhuhr: return .sunrise
        case .asr: return .dhuhr
        case .maghrib: return .asr
        case .isha: return .maghrib
        case .midnight: return .isha
        default: return .fajr
        }
    }
    
    public static func getNextPrayer(_ time: PrayTimes.TimeName) -> PrayTimes.TimeName {
        switch time {
        case .imsak: return .fajr
        case .fajr: return .sunrise
        case .sunrise: return .dhuhr
        case .dhuhr: return .asr
        case .asr: return .maghrib
        case .maghrib: return .isha
        case .isha: return .fajr
        case .midnight: return .fajr
        default: return .isha
        }
    }
    
}
