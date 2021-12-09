//
//  BusDetailsManager.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/6/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct BusDetailsManager {
    let shapeUrl = "http://www.miamidade.gov/transit/WebServices/BusRouteShapesByRoute/"
    let coordsUrl = "http://www.miamidade.gov/transit/WebServices/BusRouteShape/"
    let busTrackUrl = "http://www.miamidade.gov/transit/WebServices/BusTracker/"
    let busCoordsUrl = "http://www.miamidade.gov/transit/WebServices/Buses/"
    weak var delegate: XMLParserDelegate?
    let defaults = UserDefaults.standard
    
    func fetchRouteMap(routeID: Int, direction: String, forceRefresh: Bool = false) {
        if !forceRefresh && (defaults.data(forKey: "fetchRouteMap\(routeID)\(direction)") != nil) {
            if let data = defaults.data(forKey: "fetchRouteMap\(routeID)\(direction)") {
                print("using cached data routeMap")
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate!
                parser.parse()
            }
        } else {
            if let url = URL(string: shapeUrl + "?RouteID=\(routeID)&Dir=\(direction)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        self.defaults.set(safeData, forKey: "fetchRouteMap\(routeID)\(direction)")
                        
                        let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate!
                        parser.parse()
                    }
                })
                
                task.resume()
            }
        }
    }
    
    func fetchRouteCoords(shapeID: Int, forceRefresh: Bool = false) {
        if !forceRefresh && (defaults.data(forKey: "fetchRouteCoords\(shapeID)") != nil) {
            if let data = defaults.data(forKey: "fetchRouteCoords\(shapeID)") {
                print("using cached data routeCoords", data)
                let parser = XMLParser(data: data)
                parser.delegate = self.delegate!
                DispatchQueue.main.async(execute: {
                    parser.parse()
                })
            }
        } else {
            if let url = URL(string: coordsUrl + "?ShapeID=\(shapeID)") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error as Any)
                    }
                    
                    if let safeData = data {
                        self.defaults.set(safeData, forKey: "fetchRouteCoords\(shapeID)")
                        
                        let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate!
                        parser.parse()
                    }
                })
                
                task.resume()
            }
        }
    }
    
    func trackBus(routeID: Int, direction: String, stopID: Int) {
        if let url = URL(string: busTrackUrl + "?RouteID=\(routeID)&Dir=\(direction)&StopID=\(stopID)") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error as Any)
                }
                
                if let safeData = data {
                    if self.delegate != nil {
                    let parser = XMLParser(data: safeData)
                        parser.delegate = self.delegate!
                        parser.parse()
                    } else {
                        return
                    }
                }
            })
            
            task.resume()
        }
    }
    
    func getBusCoords(routeID: Int, direction: String) {
        if let url = URL(string: busCoordsUrl + "?RouteID=\(routeID)&Dir=\(direction)") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error as Any)
                }
                
                if let safeData = data {
                    let parser = XMLParser(data: safeData)
                    if self.delegate != nil {
                        parser.delegate = self.delegate!
                        parser.parse()
                    }
                }
            })
            
            task.resume()
        }
    }
}
