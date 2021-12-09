//
//  ScheduleController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 3/2/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class ScheduleController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {
    @IBOutlet weak var daySlider: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    var selectedIndex: Int = 0
    var scheduleDays = [String]()
    var schedule = [Schedule]()
    var index = 0
    var finishedScheduleDays = false
    let cellIdentifier = "scheduleCell"
    var selectedStop: BusStop?
    var selectedRoute: Bus?
    var elementName = ""
    var scheduleManager = ScheduleManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scheduleManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        scheduleManager.fetchRouteService(routeID: selectedRoute!.id, direction: selectedStop!.direction)
    }
    
    
    @IBAction func sliderPressed(_ sender: Any) {
        selectedIndex = daySlider.selectedSegmentIndex
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if finishedScheduleDays {
            return schedule[selectedIndex].schedule.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = schedule[selectedIndex].schedule[indexPath.row]

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updateSliderLabels() {
        daySlider.removeAllSegments()
        
        for i in 0..<scheduleDays.count {
            daySlider.insertSegment(withTitle: scheduleDays[i], at: i, animated: false)
        }
        
        daySlider.selectedSegmentIndex = 0
    }
    
    
    //XML parsing
    var scheduledTime: String = ""
    var serviceName: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" || elementName == "Sched" {
            scheduledTime = ""
            serviceName = ""
        }
        
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" || elementName == "Sched" {
            print(scheduledTime, serviceName)
            if serviceName != "" {
                scheduleDays.append(serviceName)
            } else if scheduledTime != "" {
                schedule[index - 1].schedule.append(scheduledTime)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.newlines)
        
        if (!data.isEmpty) {
            if self.elementName == "ServiceName" {
                serviceName = data
            } else if self.elementName == "SchedTime" {
                scheduledTime = data
            }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if !finishedScheduleDays {
            finishedScheduleDays = true
            
            DispatchQueue.main.async(execute: {
                self.updateSliderLabels()
            })
        }
        
        if index < scheduleDays.count {
            print("parsing schedule", index, scheduleDays.count)
            schedule.append(Schedule())
            index += 1
            DispatchQueue.main.async(execute: {
                self.scheduleManager.fetchRouteSchedule(routeID: self.selectedRoute!.id, direction: self.selectedStop!.direction, service: self.scheduleDays[self.index - 1], stopID: self.selectedStop!.stopID)
            })
        } else {
            print("done parsing")
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        }
    }
}
