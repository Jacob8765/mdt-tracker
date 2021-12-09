//
//  BusDetailsControllerViewController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/3/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class SelectStopController: UIViewController, UITableViewDataSource, UITableViewDelegate, XMLParserDelegate {
    @IBOutlet weak var busStopTableView: UITableView!
    @IBOutlet weak var directionSlider: UISegmentedControl!
    var bus: Bus? = nil
    var direction1 = [BusStop]()
    var direction2 = [BusStop]()
    let cellIdentifier = "stopCell"
    var busStopsManager = BusStopsManager()
    var direction = ""
    var selectedStop: BusStop?
    var refreshControl = UIRefreshControl()
    var selectedIndex = 0
    var elementName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(bus ?? "")
        
        //Sometimes the bus only goes one direction, so this code takes care of that
        direction = bus!.direction1
        if direction == "" {
            direction = bus!.direction2
            directionSlider.isEnabled = false
            DispatchQueue.main.async(execute: {
                self.directionSlider.removeSegment(at: 0, animated: false)
            })
        }
        
        refreshControl.addTarget(self, action: #selector(updateData), for: UIControl.Event.valueChanged)
        busStopTableView.refreshControl = refreshControl
        
        directionSlider.setTitle(bus!.direction1, forSegmentAt: 0)
        directionSlider.setTitle(bus!.direction2, forSegmentAt: 1)
        
        busStopsManager.delegate = self
        busStopsManager.fetchBusStops(routeID: bus!.id, direction: direction)
    }
    
    @objc func updateData() {
        direction1.removeAll()
        direction2.removeAll()
        busStopTableView.reloadData()
        busStopsManager.fetchBusStops(routeID: bus!.id, direction: direction, forceRefresh: true)
    }
    
    @IBAction func viewRoute(_ sender: Any) {
        performSegue(withIdentifier: "busStopRoute", sender: self)
    }
    
    @IBAction func directionSliderChanged(_ sender: Any) {
        selectedIndex = directionSlider.selectedSegmentIndex
        
        if selectedIndex == 0 {
            direction = bus!.direction1
            busStopTableView.reloadData()
        } else {
            direction = bus!.direction2
            
            if (direction2.count == 0) {
                busStopsManager.fetchBusStops(routeID: bus!.id, direction: direction)
            } else {
                busStopTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedIndex == 0 {
            return direction1.count
        }
        
        return direction2.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let stop: BusStop?
        
        if selectedIndex == 0 {
            stop = direction1[indexPath.row]
        } else {
            stop = direction2[indexPath.row]
        }
        
        cell.textLabel?.text = stop?.stopName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if selectedIndex == 0 {
            selectedStop = direction1[indexPath.row]
        } else {
            selectedStop = direction2[indexPath.row]
        }
        
        busStopTableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "busDetails", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "busDetails" {
            let detailsController = segue.destination as! BusDetailsController
            detailsController.bus = bus!
            detailsController.stop = selectedStop!
        } else {
            let routeController = segue.destination as! BusRoutesController
            routeController.bus = bus!
            routeController.direction = direction
        }
    }
    
    
    //XML parsing
    var stopID: Int = 0
    var stopName: String = ""
    var lat = 0.0
    var long = 0.0
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" {
            stopID = 0
            stopName = ""
            lat = 0.0
            long = 0.0
        }
        
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" {
            let id = stopID
            let name = stopName
            let stop = BusStop(stopID: id, stopName: name, direction: direction, coords: Coords(lat: lat, long: long))
            
            if selectedIndex == 0 {
                direction1.append(stop)
            } else {
                direction2.append(stop)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.newlines)
        
        if (!data.isEmpty) {
            if self.elementName == "StopID" {
                stopID = Int(data)!
            } else if self.elementName == "StopName" {
                stopName += data
            } else if self.elementName == "Latitude" {
                lat = Double(data)!
            } else if self.elementName == "Longitude" {
                long = Double(data)!
            }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async(execute: {
            self.busStopTableView.reloadData()
            self.refreshControl.endRefreshing()
        })
    }
}
