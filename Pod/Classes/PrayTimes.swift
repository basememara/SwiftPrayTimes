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

public class PrayTimes {
    
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
            if let name = TimeName.names[self] {
                return name
            } else {
                return ""
            }
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
                if !contains(self.params, { $0.time == item.time }) {
                    self.params.append(item)
                }
            }
        }
    }
    
    public class PrayerResult: NSObject {
        public var name: String = ""
        public var abbr: String = ""
        public var time: Double = 0
        public var date: NSDate = NSDate()
        public var formattedTime: String {
            get { return getFormattedTime() }
        }
        public var type: TimeName
        public var isFard = false
        private var timeFormat = "12h"
        private var timeSuffixes = ["am", "pm"]
        private var invalidTime =  "-----"
        
        public init(_ type: TimeName, _ time: Double, timeFormat: String? = nil, timeSuffixes: [String]? = nil) {
            self.time = time
            self.type = type
            self.name = type.getName()
            
            if let value = timeFormat {
                self.timeFormat = value
            }
            
            if let value = timeSuffixes {
                self.timeSuffixes = value
            }
            
            // Handle specific prayers
            switch (type) {
            case TimeName.Fajr:
                self.abbr = "FJR"
                self.isFard = true
                break;
            case TimeName.Sunrise:
                self.abbr = "SHK"
                break;
            case TimeName.Dhuhr:
                self.abbr = "DHR"
                self.isFard = true
                
                // Handle Friday prayer
                let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
                let flags = NSCalendarUnit.CalendarUnitWeekday
                let components = calendar?.components(flags, fromDate: date)
                if components?.weekday == 6 {
                    self.name = "Jumuah"
                }
                
                break;
            case TimeName.Asr:
                self.abbr = "ASR"
                self.isFard = true
                break;
            case TimeName.Maghrib:
                self.abbr = "MGB"
                self.isFard = true
                break;
            case TimeName.Isha:
                self.abbr = "ISH"
                self.isFard = true
                break;
            default: break;
            }
            
            // Handle times after midnight
            var ofDate = NSDate()
            if self.time > 24 {
                // Increment day
                ofDate = NSCalendar.currentCalendar()
                    .dateByAddingUnit(.CalendarUnitDay,
                        value: 1,
                        toDate: ofDate,
                        options: NSCalendarOptions(0)
                    )!
            }
            
            // Convert time to full date
            self.date = NSCalendar.currentCalendar()
                .dateBySettingHour(Int(self.time < 24 ? self.time : (self.time - 24)),
                    minute: Int((self.time - Double(Int(self.time))) * 60),
                    second: 0,
                    ofDate: ofDate,
                    options: nil
                )!
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
            
            var roundedTime = fixHour(time + 0.5 / 60) // Add 0.5 minutes to round
            var hours = floor(roundedTime)
            var minutes = round((roundedTime - hours) * 60.0)
            
            // Handle scenario when minutes is rounded to 60
            if minutes > 59 {
                hours++
                minutes = 0
            }
            
            var suffix = format == "12h" && suffixes!.count > 0 ? (hours < 12 ? suffixes![0] : suffixes![1]) : ""
            var hour = format == "24h" ? twoDigitsFormat(hours) : "\(Int((hours + 12 - 1) % 12 + 1))"
            
            var output = hour + ":" + twoDigitsFormat(minutes)
                + (suffix != "" ? " " + suffix : "")
            
            return output
        }
        
        // Add a leading 0 if necessary
        func twoDigitsFormat(num: Double!) -> String {
            return num < 10 ? "0\(Int(num))" : "\(Int(num))"
        }
        
        func fixHour(a: Double) -> Double { return fix(a, 24.0 ) }
        
        func fix(a: Double, _ b: Double) -> Double {
            let a = a - b * (floor(a / b))
            return a < 0 ? a + b : a
        }
    }
    
    public class PrayerResultSeries: NSObject {
        public var date: NSDate
        public var times: [PrayerResult]
        
        public init(date: NSDate, times: [PrayerResult]) {
            self.date = date
            self.times = times
        }
    }
    
    //------------------------ Constants --------------------------
    
    // Calculation Methods
    private let methods = [
        "MWL" : PrayerMethod("Muslim World League", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 18.0),
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Degree, value: 17.0)
            ]),
        "ISNA": PrayerMethod("Islamic Society of North America (ISNA)", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 15.0),
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Degree, value: 15.0)
            ]),
        "Egypt": PrayerMethod("Egyptian General Authority of Survey", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 19.5),
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Degree, value: 17.5)
            ]),
        "Makkah": PrayerMethod("Umm Al-Qura University, Makkah", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 18.5), // Fajr was 19 degrees before 1430 hijri
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Minute, value: 90.0)
            ]),
        "Karachi": PrayerMethod("University of Islamic Sciences, Karachi", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 18.0),
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Degree, value: 18.0)
            ]),
        "Tehran": PrayerMethod("Institute of Geophysics, University of Tehran", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 17.7),
            AdjustmentParam(time: TimeName.Maghrib, type: AdjustmentType.Degree, value: 4.5),
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Degree, value: 14.0),
            AdjustmentParam(time: TimeName.Midnight, type: AdjustmentType.Method, value: AdjustmentMethod.Jafari)
            ]),
        "Jafari": PrayerMethod("Shia Ithna-Ashari, Leva Institute, Qum", [
            AdjustmentParam(time: TimeName.Fajr, type: AdjustmentType.Degree, value: 16.0),
            AdjustmentParam(time: TimeName.Maghrib, type: AdjustmentType.Degree, value: 4.0),
            AdjustmentParam(time: TimeName.Isha, type: AdjustmentType.Degree, value: 14.0),
            AdjustmentParam(time: TimeName.Midnight, type: AdjustmentType.Method, value: AdjustmentMethod.Jafari)
            ])
    ]
    
    //---------------------- Default Settings --------------------
    
    private static let defaultParams = [
        AdjustmentParam(
            time: TimeName.Maghrib,
            type: AdjustmentType.Minute,
            value: 0.0
        ),
        AdjustmentParam(
            time: TimeName.Midnight,
            type: AdjustmentType.Method,
            value: AdjustmentMethod.Standard
        )
    ]
    
    private static let defaultSettings = [
        AdjustmentParam(time: TimeName.Imsak, type: AdjustmentType.Minute, value: 10.0),
        AdjustmentParam(time: TimeName.Dhuhr, type: AdjustmentType.Minute, value: 0.0),
        AdjustmentParam(time: TimeName.Asr, type: AdjustmentType.Method, value: AdjustmentMethod.Standard)
    ]
    
    private static let defaultTimes: [TimeName: Double] = [
        TimeName.Imsak: 5.0,
        TimeName.Fajr: 5.0,
        TimeName.Sunrise: 6.0,
        TimeName.Dhuhr: 12.0,
        TimeName.Asr: 13.0,
        TimeName.Sunset: 18.0,
        TimeName.Maghrib: 18.0,
        TimeName.Isha: 18.0
    ]
    
    // Do not change anything here; use adjust method instead
    private var calcMethod = "MWL"
    private var highLats = ElavationMethod.NightMiddle
    private var settings = defaultSettings
    
    public var timeFormat = "12h"
    public var timeSuffixes = ["am", "pm"]
    private var timeZone =  Double(0)
    private var jDate =  Double(0)
    private var invalidTime =  "-----"
    
    private var lat = Double(0)
    private var lng = Double(0)
    private var elv = Double(0)
    
    private var numIterations = 1
    private var offset: [TimeName: Double] = [
        TimeName.Imsak: 0.0,
        TimeName.Fajr: 0.0,
        TimeName.Sunrise: 0.0,
        TimeName.Dhuhr: 0.0,
        TimeName.Asr: 0.0,
        TimeName.Sunset: 0.0,
        TimeName.Maghrib: 0.0,
        TimeName.Isha: 0.0,
        TimeName.Midnight: 0.0
    ]
    
    //---------------------- Initialization -----------------------
    
    public init(method: String? = nil, juristic: AdjustmentMethod? = nil) {
        setMethod(method ?? calcMethod)
        
        // Update juristic method if applicable
        if let j = juristic {
            //for item in settings {
            for (index, item) in enumerate(settings) {
                if item.type == .Method {
                    settings[index].value = j
                }
            }
        }
    }
    
    //-------------------- Interface Functions --------------------
    
    public func setMethod(method: String) {
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
    
    public func adjust(params: [AdjustmentParam]) {
        for item in params {
            settings = settings.filter { $0.time != item.time } // Remove duplicate
            settings.append(item)
        }
    }
    
    public func tune(timeOffsets: [TimeName: Double]) {
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
        return setting.type == AdjustmentType.Minute || setting.type == AdjustmentType.Degree
            ? getSetting(time).value as! Double : 0.0
    }
    
    // Get prayer times for a given date
    public func getTimes(
        coords: [Double],
        date: NSDate = NSDate(),
        timezone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        completion: (times: [TimeName: PrayerResult]) -> Void) -> Void {
            lat = coords[0]
            lng = coords[1]
            elv = coords.count > 2 ? coords[2] : 0
            jDate = getJulian(date) - lng / (15 * 24)
            timeFormat = format ?? timeFormat
            
            let deferredTask: () -> Void = {
                // Create array of prayers with details
                var result = [TimeName: PrayerResult]()
                for (key, value) in self.computeTimes() {
                    result[key] = PrayerResult(key, value,
                        timeFormat: self.timeFormat, timeSuffixes: self.timeSuffixes)
                }
                
                // Process callback
                completion(times: result)
            }
            
            // Calculate timezone
            if let tz = timezone {
                timeZone = tz
                
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
                        var err: NSError?
                        var jsonData = NSJSONSerialization.JSONObjectWithData(data,
                            options: NSJSONReadingOptions.MutableContainers,
                            error: &err) as! NSDictionary
                        
                        if (err == nil) {
                            self.timeZone = jsonData["rawOffset"] as! Double / 60.0 / 60.0
                            
                            // Factor in daylight if applicable
                            if dst {
                                self.timeZone += (jsonData["dstOffset"] as! Double / 60.0 / 60.0)
                            }
                            
                            deferredTask()
                        } else {
                            println("JSON Error \(err!.localizedDescription)")
                        }
                    } else {
                        println(error.localizedDescription)
                    }
                    }.resume()
            }
    }
    
    public func getTimesForRange(
        coords: [Double],
        endDate: NSDate,
        date: NSDate = NSDate(),
        timezone: Double? = nil,
        dst: Bool = false,
        dstOffset: Int = 3600,
        format: String? = nil,
        isLocalCoords: Bool = true, // Should set to false if coordinate in parameter not device
        completion: (series: [PrayerResultSeries]) -> Void) -> Void {
            
            // Initialize variables
            var series: [PrayerResultSeries]! = []
            var startDate = NSCalendar.currentCalendar()
                .dateByAddingUnit(.CalendarUnitDay,
                    value: -1,
                    toDate: date,
                    options: NSCalendarOptions(0)
                )!
            
            // Iterate date range to generate prayer times per day
            while startDate.compare(endDate) == .OrderedAscending {
                startDate = NSCalendar.currentCalendar()
                    .dateByAddingUnit(.CalendarUnitDay,
                        value: 1,
                        toDate: startDate,
                        options: NSCalendarOptions(0)
                    )!
                
                // Retrieve prayer times for day
                getTimes(coords,
                    date: startDate,
                    timezone: timezone,
                    dst: dst,
                    dstOffset: dstOffset,
                    format: format,
                    isLocalCoords: isLocalCoords,
                    completion: {
                    (times: [TimeName: PrayerResult]) in
                    
                    // Pluck only times array and sort by time
                    let sortedTimes = times.values.array.sorted {
                        $0.time < $1.time
                    }
                    
                    series.append(PrayerResultSeries(date: startDate, times: sortedTimes))
                    
                    // Populate table again
                    if NSCalendar.currentCalendar().startOfDayForDate(startDate)
                        .compare(NSCalendar.currentCalendar().startOfDayForDate(endDate)) == .OrderedSame {
                            // Process callback
                            completion(series: series)
                    }
                })
            }
    }
    
    //---------------------- Compute Prayer Times -----------------------
    
    
    // Compute prayer times
    public func computeTimes() -> [TimeName: Double] {
        var times = computePrayerTimes(PrayTimes.defaultTimes)
        
        times = adjustTimes(times)
        
        // Add midnight time
        var midnight = getSetting(TimeName.Midnight);
        times[TimeName.Midnight] = midnight.type == AdjustmentType.Method
            && (midnight.value as! AdjustmentMethod) == AdjustmentMethod.Jafari
            ? times[TimeName.Sunset]! + timeDiff(times[TimeName.Sunset], times[TimeName.Fajr]) / 2
            : times[TimeName.Sunset]! + timeDiff(times[TimeName.Sunset], times[TimeName.Sunrise]) / 2
        
        times = tuneTimes(times);
        
        return times
    }
    
    // Compute prayer times at given julian date
    public func computePrayerTimes(var times: [TimeName: Double]) -> [TimeName: Double] {
        times = dayPortion(times)
        
        var imsak = sunAngleTime(getSettingValue(TimeName.Imsak),
            time: times[TimeName.Imsak],
            direction: "ccw")
        
        var fajr = sunAngleTime(getSettingValue(TimeName.Fajr),
            time: times[TimeName.Fajr],
            direction: "ccw")
        
        var sunrise = sunAngleTime(riseSetAngle(),
            time: times[TimeName.Sunrise],
            direction: "ccw")
        
        var dhuhr = midDay(times[TimeName.Dhuhr])
        
        var asr = asrTime(times[TimeName.Asr])
        
        var sunset = sunAngleTime(riseSetAngle(),
            time: times[TimeName.Sunset])
        
        var maghrib = sunAngleTime(getSettingValue(TimeName.Maghrib),
            time: times[TimeName.Maghrib])
        
        var isha = sunAngleTime(getSettingValue(TimeName.Isha),
            time: times[TimeName.Isha])
        
        return [
            TimeName.Imsak: imsak,
            TimeName.Fajr: fajr,
            TimeName.Sunrise: sunrise,
            TimeName.Dhuhr: dhuhr,
            TimeName.Asr: asr,
            TimeName.Sunset: sunset,
            TimeName.Maghrib: maghrib,
            TimeName.Isha: isha
        ]
    }
    
    //---------------------- Calculation Functions -----------------------
    
    
    // Compute mid-day time
    public func midDay(time: Double!) -> Double {
        var eqt = sunPosition(jDate + time)["equation"]!
        var noon = fixHour(12.0 - eqt)
        return noon
    }
    
    // Compute the time at which sun reaches a specific angle below horizon
    public func sunAngleTime(angle: Double!, time: Double!, direction: String? = nil) -> Double {
        var decl = sunPosition(jDate + time)["declination"]!
        var noon = midDay(time)
        
        var t = 1 / 15 * self.arccos(
            (-self.sin(angle) - self.sin(decl) * self.sin(lat))
                / (self.cos(decl) * self.cos(lat)))
        
        return noon + (direction == "ccw" ? -t : t)
    }
    
    // Compute declination angle of sun and equation of time
    // Ref: http://aa.usno.navy.mil/faq/docs/SunApprox.php
    public func sunPosition(jd: Double) -> [String: Double] {
        var D = jd - 2451545.0
        var g = fixAngle(357.529 + 0.98560028 * D)
        var q = fixAngle(280.459 + 0.98564736 * D)
        var L = fixAngle(q + 1.915 * self.sin(g) + 0.020 * self.sin(2 * g))
        
        var R = 1.00014 - 0.01671 * self.cos(g) - 0.00014 * self.cos(2 * g)
        var e = 23.439 - 0.00000036 * D
        
        var RA = self.arctan2(self.cos(e) * self.sin(L), self.cos(L)) / 15.0
        var eqt = q / 15.0 - fixHour(RA)
        var decl = self.arcsin(self.sin(e) * self.sin(L))
        
        return [
            "declination": decl,
            "equation": eqt
        ]
    }
    
    // Get sun angle for sunset/sunrise
    public func riseSetAngle() -> Double {
        //var earthRad = 6371009; // in meters
        //var angle = DMath.arccos(earthRad/(earthRad+ elv));
        var angle = 0.0347 * sqrt(elv) // an approximation
        return 0.833 + angle
    }
    
    // Convert Gregorian date to Julian day
    // Ref: Astronomical Algorithms by Jean Meeus
    public func getJulian(date: NSDate) -> Double {
        let flags: NSCalendarUnit = .CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear
        let components = NSCalendar.currentCalendar().components(flags, fromDate: date)
        
        if components.month <= 2 {
            components.year -= 1
            components.month += 12
        }
        
        var A = floor(Double(components.year) / Double(100));
        var B = 2 - A + floor(A / Double(4));
        
        var JD = floor(Double(365.25) * Double(components.year + 4716))
            + floor(Double(30.6001) * Double(components.month + 1))
            + Double(components.day) + B - 1524.5
        
        return JD;
    }
    
    // Adjust times
    public func adjustTimes(var times: [TimeName: Double]) -> [TimeName: Double] {
        for item in times {
            times[item.0] = times[item.0]!
                + (Double(timeZone) - lng / 15)
        }
        
        if highLats != ElavationMethod.None {
            times = adjustHighLats(times);
        }
        
        let imsak = getSetting(TimeName.Imsak)
        if (imsak.type == AdjustmentType.Minute) {
            times[TimeName.Imsak] = times[TimeName.Fajr]!
                - (imsak.value as! Double) / 60.0
        }
        
        let maghrib = getSetting(TimeName.Maghrib)
        if (maghrib.type == AdjustmentType.Minute) {
            times[TimeName.Maghrib] = times[TimeName.Sunset]!
                + (maghrib.value as! Double) / 60.0
        }
        
        let isha = getSetting(TimeName.Isha)
        if (isha.type == AdjustmentType.Minute) {
            times[TimeName.Isha] = times[TimeName.Maghrib]!
                + (isha.value as! Double) / 60.0
        }
        
        times[TimeName.Dhuhr] = times[TimeName.Dhuhr]!
            + getSettingValue(TimeName.Dhuhr) / 60.0
        
        return times;
    }
    
    // Adjust times for locations in higher latitudes
    public func adjustHighLats(var times: [TimeName: Double]) -> [TimeName: Double] {
        var nightTime = timeDiff(times[TimeName.Sunset], times[TimeName.Sunrise])
        
        times[TimeName.Imsak] = adjustHLTime(times[TimeName.Imsak],
            base: times[TimeName.Sunrise],
            angle: getSettingValue(TimeName.Imsak),
            night: nightTime,
            direction: "ccw")
        
        times[TimeName.Fajr]  = adjustHLTime(times[TimeName.Fajr],
            base: times[TimeName.Sunrise],
            angle: getSettingValue(TimeName.Fajr),
            night: nightTime,
            direction: "ccw")
        
        times[TimeName.Isha]  = adjustHLTime(times[TimeName.Isha],
            base: times[TimeName.Sunset],
            angle: getSettingValue(TimeName.Isha),
            night: nightTime)
        
        times[TimeName.Maghrib] = adjustHLTime(times[TimeName.Maghrib],
            base: times[TimeName.Sunset],
            angle: getSettingValue(TimeName.Maghrib),
            night: nightTime)
        
        return times;
    }
    
    // Adjust times for locations in higher latitudes
    public func adjustHLTime(var time: Double!, base: Double!, angle: Double!, night: Double!, direction: String? = nil) -> Double {
        var portion = nightPortion(angle, night)
        
        var diff = direction == "ccw"
            ? timeDiff(time, base)
            : timeDiff(base, time)
        
        if (time.isNaN || diff > portion) {
            time = base + (direction == "ccw" ? -portion : portion)
        }
        
        return time
    }
    
    // The night portion used for adjusting times in higher latitudes
    public func nightPortion(angle: Double!, _ night: Double!) -> Double {
        var portion = 1.0 / 2.0 // MidNight
        
        if highLats == ElavationMethod.AngleBased {
            portion = 1.0 / 60.0 * angle;
        }
        
        if highLats == ElavationMethod.OneSeventh {
            portion = 1.0 / 7.0;
        }
        
        return portion * night;
    }
    
    // Convert hours to day portions
    public func dayPortion(var times: [TimeName: Double]) -> [TimeName: Double] {
        for item in times {
            times[item.0] = times[item.0]! / 24.0
        }
        
        return times
    }
    
    // Apply offsets to the times
    public func tuneTimes(var times: [TimeName: Double]) -> [TimeName: Double] {
        for item in times {
            times[item.0] = times[item.0]! + offset[item.0]! / 60.0
        }
        
        return times
    }
    
    // Compute asr time
    public func asrTime(time: Double!) -> Double {
        let param = getSetting(TimeName.Asr)
        let factor = asrFactor(param)
        var decl = sunPosition(jDate + time)["declination"]!
        var angle = -self.arccot(factor + self.tan(abs(lat - decl)))
        return sunAngleTime(angle, time: time)
    }
    
    // Get asr shadow factor
    public func asrFactor(asrParam: AdjustmentParam) -> Double {
        if asrParam.type == AdjustmentType.Method {
            let method = asrParam.value as! AdjustmentMethod
            
            return method == AdjustmentMethod.Standard ? 1
                : method == AdjustmentMethod.Hanafi ? 2
                : getSettingValue(asrParam.time)
        }
        
        return getSettingValue(asrParam.time);
    }
    
    //---------------------- Misc Functions -----------------------
    
    // Compute the difference between two times
    public func timeDiff(time1: Double!, _ time2: Double!) -> Double {
        return fixHour(time2 - time1);
    }
    
    //----------------- Degree-Based Math Functions -------------------
    
    public func dtr(d: Double) -> Double { return (d * M_PI) / 180.0 }
    public func rtd(r: Double) -> Double { return (r * 180.0) / M_PI }
    
    public func sin(d: Double) -> Double { return Darwin.sin(dtr(d)) }
    public func cos(d: Double) -> Double { return Darwin.cos(dtr(d)) }
    public func tan(d: Double) -> Double { return Darwin.tan(dtr(d)) }
    
    public func arcsin(d: Double) -> Double { return rtd(Darwin.asin(d)) }
    public func arccos(d: Double) -> Double { return rtd(Darwin.acos(d)) }
    public func arctan(d: Double) -> Double { return rtd(Darwin.atan(d)) }
    
    public func arccot(x: Double) -> Double { return rtd(Darwin.atan(1 / x)) }
    public func arctan2(y: Double, _ x: Double) -> Double { return rtd(Darwin.atan2(y, x)) }
    
    public func fixAngle(a: Double) -> Double { return fix(a, 360.0) }
    public func fixHour(a: Double) -> Double { return fix(a, 24.0 ) }
    
    public func fix(a: Double, _ b: Double) -> Double {
        let a = a - b * (floor(a / b))
        return a < 0 ? a + b : a
    }
    
}
