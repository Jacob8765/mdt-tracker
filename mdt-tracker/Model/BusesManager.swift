//
//  BusesManager.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/2/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct BusesManager {
    weak var delegate: XMLParserDelegate?
    var busDirections = "http://www.miamidade.gov/transit/WebServices/BusRouteDirections/"
    var busRoutes = "http://www.miamidade.gov/transit/WebServices/BusRoutes/"
    let defaults = UserDefaults.standard
    
    func fetchBuses(forceLoad: Bool = false) {
        if !forceLoad && (defaults.data(forKey: "fetchBuses") != nil) {
            if let data = defaults.data(forKey: "fetchBuses") {
                print("using cached data buses")
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate
                parser.parse()
                self.fetchBusDirections()
            }
        } else {
            if let url = URL(string: busRoutes) {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        self.defaults.set(safeData, forKey: "fetchBuses")
                        
                        let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate
                        parser.parse()
                        self.fetchBusDirections(forceLoad: true)
                    }
                })
                
                task.resume()
            }
        }
    }
    
    func fetchBusDirections(forceLoad: Bool = false) {
        if !forceLoad && (defaults.data(forKey: "fetchBusDirections") != nil) {
            if let data = defaults.data(forKey: "fetchBusDirections") {
                print("using cached data")
                let data = Data(data)
                
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate
                parser.parse()
            }
        } else {
            if let url = URL(string: busDirections) {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        print("fetched directions")
                        self.defaults.set(safeData, forKey: "fetchBusDirections")
                        
                        let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate
                        parser.parse()
                    }
                })
                
                task.resume()
            }
        }
    }
}


