//
//  BusRoutesManager.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/3/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct BusStopsManager {
    let busStopsAPI = "http://www.miamidade.gov/transit/WebServices/BusRouteStops/?RouteId="
    weak var delegate: XMLParserDelegate?
    let defaults = UserDefaults.standard
    
    func fetchBusStops(routeID: Int, direction: String, forceRefresh: Bool = false) {
        if direction == "" {
            print("Only one direction")
            return
        }
        
        if !forceRefresh && (defaults.data(forKey: "fetchBusStops\(routeID)\(direction)") != nil) {
            if let data = defaults.data(forKey: "fetchBusStops\(routeID)\(direction)") {
                print("using cached data")
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate!
                parser.parse()
            }
        } else {
            if let url = URL(string: busStopsAPI + "\(routeID)&Dir=\(direction)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        self.defaults.set(safeData, forKey: "fetchBusStops\(routeID)\(direction)")
                        
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
