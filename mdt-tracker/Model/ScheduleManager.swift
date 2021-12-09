//
//  ScheduleManager.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 3/4/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct Schedule {
    var schedule = [String]()
}

struct ScheduleManager {
    let routeService = "http://www.miamidade.gov/transit/WebServices/BusRouteService/"
    let routeSchedule = "http://www.miamidade.gov/transit/WebServices/BusSchedules/"
    weak var delegate: XMLParserDelegate?
    let defaults = UserDefaults.standard
    
    func fetchRouteService(routeID: Int, direction: String, forceRefresh: Bool = false) {
        if !forceRefresh && (defaults.data(forKey: "fecthRouteService\(routeID)\(direction)") != nil) {
            if let data = defaults.data(forKey: "fetchRouteService\(routeID)\(direction)") {
                print("using cached data")
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate!
                parser.parse()
            }
        } else {
            if let url = URL(string: routeService + "?RouteID=\(routeID)&Dir=\(direction)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        self.defaults.set(safeData, forKey: "fetchRouteService\(routeID)\(direction)")
                        
                        let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate!
                        parser.parse()
                    }
                })
                
                task.resume()
            }
        }
    }
    
    func fetchRouteSchedule(routeID: Int, direction: String, service: String, stopID: Int, forceRefresh: Bool = false) {
        if !forceRefresh && (defaults.data(forKey: "fetchRouteSchedule\(routeID)\(service)\(direction)\(stopID)") != nil) {
            if let data = defaults.data(forKey: "fetchRouteSchedule\(routeID)\(service)\(direction)\(stopID)") {
                print("using cached data")
                //print(String(data: data, encoding: .utf8))
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate!
                parser.parse()
            }
        } else {
            if let url = URL(string: routeSchedule + "?RouteID=\(routeID)&Service=\(service)&Dir=\(direction)&stopID=\(stopID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        self.defaults.set(safeData, forKey: "fetchRouteSchedule\(routeID)\(service)\(direction)\(stopID)")
                        
                        let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate!
                        parser.parse()
                    }
                })
                
                task.resume()
            }
        }
    }
}
