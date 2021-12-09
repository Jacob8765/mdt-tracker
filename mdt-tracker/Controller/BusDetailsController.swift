//
//  BusDetailsController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/4/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit
import MapKit

class BusDetailsController: UIViewController, XMLParserDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var busNotRunningView: UIView!
    @IBOutlet weak var scheduleButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var tableViewParent: UIView!
    @IBOutlet weak var busNotRunningLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var busDetailsTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var busDetailsManager = BusDetailsManager()
    var bus: Bus?
    var stop: BusStop?
    var elementName = ""
    var shapes = [Int]()
    var busEstArrivals = [String]()
    var busNames = [String]()
    var busCoords: [Coords] = []
    let cellIdentifier: String = "busDetailsCell"
    var routeAdded: Bool = false
    var didTrackBus: Bool = false
    var timer: Timer?
    var favoritesManager = FavoritesManager()
    var isFavorite = false
    var shapeCount = 0
    var busMaps = [BusMap]()
    var busLocationUpdated = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        mapView.delegate = self
        
        busDetailsTable.layer.cornerRadius = 35.0
        busDetailsTable.layer.masksToBounds = true
        busDetailsTable.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tableViewParent.layer.cornerRadius = 35.0
        tableViewParent.layer.masksToBounds = true
        tableViewParent.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        busNotRunningLabel.layer.cornerRadius = 35.0
        busNotRunningView.layer.cornerRadius = 35.0
        busNotRunningView.layer.masksToBounds = true
        busNotRunningView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        scheduleButton.layer.cornerRadius = 7.0
        routeButton.layer.cornerRadius = 7.0
        favoriteButton.layer.cornerRadius = 7.0
        
        busDetailsManager.delegate = self
        busDetailsManager.fetchRouteMap(routeID: bus!.id, direction: stop!.direction)
    }
    
    @IBAction func refreshData(_ sender: UIBarButtonItem) {
        updateBusData() //Update the data when the refresh button is pressed
    }
    
    @IBAction func busRoutePressed(_ sender: Any) {
        performSegue(withIdentifier: "busDetailsRoute", sender: self)
    }
    
    @IBAction func scheduleButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "schedule", sender: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate() //Stop the timer on changing views
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFavoritesButton()
        if didTrackBus {
            timer?.fire()
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            print("Location services disabled")
        }
    }
    
    @IBAction func favoriteButtonPressed(_ sender: UIButton) {
        let favorite = Favorite(bus: bus!, stop: stop!)
        
        if isFavorite {
            favoritesManager.removeFavorite(favorite: favorite)
        } else {
            favoritesManager.addFavorite(favorite: favorite)
        }
        
        refreshFavoritesButton()
    }
    
    func refreshFavoritesButton() {
        isFavorite = favoritesManager.containsBus(routeID: bus!.id, direction: stop!.direction, stopID: stop!.stopID)

        if isFavorite {
            favoriteButton.backgroundColor = UIColor.systemRed
            favoriteButton.setTitle("Remove from favorites", for: .normal)
        } else {
            favoriteButton.backgroundColor = UIColor.systemBlue
            favoriteButton.setTitle("Favorite", for: .normal)
        }
    }
    
    func busNotRunning() {
        DispatchQueue.main.async(execute: {
            self.busDetailsTable.isHidden = true
            self.busNotRunningView.isHidden = false
            self.timer?.invalidate()
        })
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
        case .denied: // Show alert telling users how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            mapView.showsUserLocation = true
        case .restricted: // Show an alert letting them know what’s up
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("unknown")
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        for bus in busNames { //If there are less than three scheduled buses left in the day, some of them will be blank
            if bus != "" {
                count += 1
            }
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BusDetailsTableViewCell
        
        cell.busNameLabel.text = busNames[indexPath.row]
        cell.busIconParentView.layer.cornerRadius = 24
        
        let busArrival = busEstArrivals[indexPath.row]
        if busNames[indexPath.row] == "TBD" {
            let updatedArrival = busArrival.prefix(busArrival.count - 2)
            cell.busTimeLabel.text = "\(updatedArrival)"
        } else {
            cell.busTimeLabel.text = "\(busEstArrivals[indexPath.row])"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        polylineRenderer.strokeColor = UIColor.systemBlue
        polylineRenderer.lineWidth = 4.25
        return polylineRenderer
    }
    
    func addRoute() {
        routeAdded = true
        var polyline: MKPolyline?
        
        for i in 0..<shapes.count {
            let busRouteCoords = busMaps[i].coords
            
            var locations = [CLLocationCoordinate2D]()
            for i in 0..<busRouteCoords.count {
                let coord = CLLocationCoordinate2D(latitude: busRouteCoords[i].lat, longitude: busRouteCoords[i].long)
                locations.append(coord)
            }
            
            polyline = MKPolyline(coordinates: locations, count: locations.count)
            mapView.addOverlay(polyline!)
        }
        
        mapView.setRegion(MKCoordinateRegion(polyline!.boundingMapRect), animated: true)
    }
    
    func trackBus() {
        didTrackBus = true
        updateBusData()
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 15,
                                              target: self,
                                              selector: #selector(self.updateBusData),
                                              userInfo: nil,
                                              repeats: true)
        }
    }
    
    @objc func updateBusData() {
        busLocationUpdated.removeAll()
        busCoords.removeAll()
        
        busDetailsManager.trackBus(routeID: bus!.id, direction: stop!.direction, stopID: stop!.stopID)
        busDetailsManager.getBusCoords(routeID: bus!.id, direction: stop!.direction)
    }
    
    func addBusMarker() {
        mapView.removeAnnotations(mapView.annotations)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        let currentDate = dateFormatter.date(from: dateFormatter.string(from: Date()))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        for i in 0..<busCoords.count {
            if busCoords[i].lat == 0.0 {
                return
            }
            
            let busPositionAnnotation = MKPointAnnotation()
            busPositionAnnotation.coordinate = CLLocationCoordinate2D(latitude: busCoords[i].lat, longitude: busCoords[i].long)
            
            let index = busLocationUpdated[i].index(busLocationUpdated[i].startIndex, offsetBy: busLocationUpdated[i].count - 3)
            let substring = busLocationUpdated[i][..<index] // remove the AM/PM from the end of the string
            
            let busTime = dateFormatter.date(from: String(substring))
            let relativeDate = formatter.localizedString(for: busTime!, relativeTo: currentDate!)
            
            busPositionAnnotation.title = relativeDate
            
            mapView.addAnnotation(busPositionAnnotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        let reuseId = "BusLocationMarker"
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            anView!.frame.size = CGSize(width: 28.5, height: 28.5)
            anView!.backgroundColor = UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)
            anView!.layer.cornerRadius = 15.0
            anView!.canShowCallout = true
            
            let image = UIImageView(image: UIImage(named: "bus_icon")!.withRenderingMode(.alwaysTemplate))
            image.tintColor = UIColor.white
            image.frame.size = CGSize(width: 21.0, height: 21.0)
            image.center = CGPoint(x: anView!.frame.width / 2, y: anView!.frame.height / 2)
            anView!.addSubview(image)
        }
        else {
            anView!.annotation = annotation
        }
        
        return anView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "busDetailsRoute" {
            let destination = segue.destination as! BusRoutesController
            destination.bus = bus!
            destination.direction = stop!.direction
        } else {
            let destination = segue.destination as! ScheduleController
            destination.selectedRoute = bus!
            destination.selectedStop = stop!
        }
    }
    
    
    
    //XML parsing
    var didFinishShapes = false
    var shapeID: Int = 0
    var lat: Double = 0.0
    var long: Double = 0.0
    var busName1: String = ""
    var busEstArrival1: String = ""
    var busName2: String = ""
    var busEstArrival2: String = ""
    var busName3: String = ""
    var busEstArrival3: String = ""
    var busLat: Double = 0.0
    var busLong: Double = 0.0
    var busName: String = ""
    var busUpdated: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" {
            shapeID = 0
            lat = 0.0
            long = 0.0
            busName1 = ""
            busEstArrival1 = ""
            busName2 = ""
            busEstArrival2 = ""
            busName3 = ""
            busEstArrival3 = ""
            busLat = 0.0
            busLong = 0.0
            busName = ""
            busUpdated = ""
        }
        
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" {
            if shapeID != 0 {
                shapes.append(shapeID)
            } else if lat != 0.0 {
                busMaps[busMaps.count - 1].coords.append(Coords(lat: lat, long: long))
            } else if busLat != 0.0 {
                busCoords.append(Coords(lat: busLat, long: busLong))
                busLocationUpdated.append(busUpdated)
            } else {
                busEstArrivals = [busEstArrival1, busEstArrival2, busEstArrival3]
                busNames = [busName1, busName2, busName3]
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.newlines)
        
        if (!data.isEmpty) {
            if self.elementName == "ShapeID" {
                shapeID = Int(data)!
            } else if self.elementName == "Latitude" {
                if routeAdded { //Both the bus and route coordinates have a field named latitude and longitude, so we have to check if it already parsed the route
                    busLat = Double(data)!
                } else {
                    lat = Double(data)!
                }
            } else if self.elementName == "Longitude" {
                if routeAdded {
                    busLong = Double(data)!
                } else {
                    long = Double(data)!
                }
            } else if self.elementName == "Time1_Bus_Name" {
                busName1 = data
            } else if self.elementName == "Time2_Bus_Name" {
                busName2 = data
            } else if self.elementName == "Time3_Bus_Name" {
                busName3 = data
            } else if self.elementName == "Time1" {
                busEstArrival1 = data
            } else if self.elementName == "Time2" {
                busEstArrival2 = data
            } else if self.elementName == "Time3" {
                busEstArrival3 = data
            } else if self.elementName == "BusName" {
                busName = data
            } else if self.elementName == "LocationUpdated" {
               busUpdated = data
           }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if shapes.count > shapeCount {
            print("updating shapes...", shapes, shapes[shapeCount], shapeCount)
            busMaps.append(BusMap())
            busDetailsManager.fetchRouteCoords(shapeID: shapes[shapeCount])
            shapeCount += 1
        } else {
            if !routeAdded {
                DispatchQueue.main.async(execute: {
                    self.addRoute()
                })
            }
            
            if busNames.count > 0 {
                    if busEstArrivals[0] == "*****" {
                        busNotRunning()
                    }
                    
                    if busLocationUpdated.count > 0 { //ADDED
                        DispatchQueue.main.async(execute: {
                            self.addBusMarker()
                        })
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.busDetailsTable.reloadData() //This should probably not get called every time... there has to be a better way
                    })
            }
            
            if !didTrackBus {
                trackBus()
            }
        }
        
        didFinishShapes = true
    }
}
