//
//  BusesController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/1/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class BusesController: UIViewController, UITableViewDataSource, UITableViewDelegate, XMLParserDelegate {
    @IBOutlet weak var busesTableView: UITableView!
    var buses = [Bus]()
    let cellIdentifier = "BusesTableViewCellReuseIdentifier"
    var busesManager = BusesManager()
    var selectedBus: Bus?
    var refreshControl = UIRefreshControl()
    var elementName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        refreshControl.addTarget(self, action: #selector(updateData), for: UIControl.Event.valueChanged)
        busesTableView.refreshControl = refreshControl
        
        busesManager.delegate = self
        busesManager.fetchBuses()
        
        busesTableView.register(UINib(nibName: "BusesTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
    }
    
    @objc func updateData() {
        buses.removeAll()
        busesTableView.reloadData()
        busesManager.fetchBuses(forceLoad: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BusesTableViewCell
          let bus = buses[indexPath.row]
        
          cell.busShortNameLabel.text = bus.name
          cell.busExtendedNameLabel.text = bus.extendedName
          cell.busNumberLabel.text = "\(bus.id)"
         
          return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bus = buses[indexPath.row]
        selectedBus = bus
        
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "busStops", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailsController = segue.destination as! SelectStopController
        detailsController.bus = selectedBus
    }
    
    
    
    
    //XML parsing
    var routeId: Int = 0
    var routeAlias: String = ""
    var routeAliasLong: String = ""
    var direction: String = ""
    var directionID: Int = 0
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" {
            routeId = 0
            direction = ""
            directionID = 0
            routeAlias = ""
            routeAliasLong = ""
            direction = ""
            directionID = 0
        }
        
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" {
            let id = routeId
            let alias = routeAlias
            let extendedAlias = routeAliasLong
            
            if (direction != "") {
                for i in 0..<buses.count {
                    if buses[i].id == routeId {
                        if directionID == 0 {
                            buses[i].direction2 = direction
                        } else {
                            buses[i].direction1 = direction
                        }
                        
                        break
                    }
                }
            } else {
                buses.append(Bus(id: id, name: alias, extendedName: extendedAlias, direction1: "", direction2: ""))
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!data.isEmpty) {
            if self.elementName == "RouteID" {
                routeId = Int(data) ?? 0
            } else if self.elementName == "RouteAlias" {
                routeAlias = data
            } else if self.elementName == "RouteAliasLong" {
                routeAliasLong = data
            }  else if self.elementName == "Direction" {
                direction = data
            }  else if self.elementName == "DirectionID" {
                directionID = Int(data) ?? 0
            }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async(execute: {
            self.refreshControl.endRefreshing()
            self.busesTableView.reloadData()
        })
    }
}

