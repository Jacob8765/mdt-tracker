//
//  BusRoutesController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/9/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit
import MapKit

class BusRoutesController: UIViewController, MKMapViewDelegate, XMLParserDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var bus: Bus?
    var direction: String?
    var manager = BusDetailsManager()
    var busStopsManager = BusStopsManager()
    var busMaps = [BusMap]()
    let locationManager = CLLocationManager()
    var shapeCount = 0
    var elementName = ""
    var shapes = [Int]()
    var busPin: MKPinAnnotationView!
    var busStops = [BusStop]()
    var routeAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        busStopsManager.delegate = self
        mapView.delegate = self
        checkLocationServices()
        manager.fetchRouteMap(routeID: bus!.id, direction: direction!)
    }
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        polylineRenderer.strokeColor = UIColor.systemBlue
        polylineRenderer.lineWidth = 4.5
        return polylineRenderer
    }
    
    func addRoute() {
        routeAdded = true
        
        for i in 0..<shapes.count {
            let busRouteCoords = busMaps[i].coords
            
            var locations = [CLLocationCoordinate2D]()
            for i in 0..<busRouteCoords.count {
                let coord = CLLocationCoordinate2D(latitude: busRouteCoords[i].lat, longitude: busRouteCoords[i].long)
                locations.append(coord)
            }
            
            let polyline = MKPolyline(coordinates: locations, count: locations.count)
            self.mapView.setRegion(MKCoordinateRegion(polyline.boundingMapRect), animated: true)
            mapView.addOverlay(polyline)
        }
    }
    
    func addBusStopMarker() {
        print(busStops.count)
        mapView.removeAnnotations(mapView.annotations)
        
        for stop in busStops {
            if stop.coords.lat == 0.0 {
                return
            }
            
            let busPositionAnnotation = MKPointAnnotation()
            busPositionAnnotation.coordinate = CLLocationCoordinate2D(latitude: stop.coords.lat, longitude: stop.coords.long)
            busPositionAnnotation.subtitle = stop.stopName
            mapView.addAnnotation(busPositionAnnotation)
        }
    }
    
    
    
    
    //XML Parsing
    var didFinishShapes = false
    var shapeID: Int = 0
    var lat: Double = 0.0
    var long: Double = 0.0
    var stopID: Int = 0
    var stopLat: Double = 0.0
    var stopLong: Double = 0.0
    var stopName: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" {
            shapeID = 0
            lat = 0.0
            long = 0.0
            stopID = 0
            stopName = ""
            stopLat = 0.0
            stopLong = 0.0
        }
        
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" {
            if shapeID != 0 {
                shapes.append(shapeID)
            } else if lat != 0.0 {
                busMaps[busMaps.count - 1].coords.append(Coords(lat: lat, long: long))
            } else if stopLat != 0.0 {
                busStops.append(BusStop(stopID: stopID, stopName: stopName, direction: direction!, coords: Coords(lat: stopLat, long: stopLong)))
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.newlines)
        
        if (!data.isEmpty) {
            if self.elementName == "ShapeID" {
                shapeID = Int(data)!
            } else if self.elementName == "StopID" {
                stopID = Int(data)!
            } else if self.elementName == "StopName" {
                stopName += data
            } else if self.elementName == "Latitude" {
                if routeAdded {
                    stopLat = Double(data)!
                } else {
                    lat = Double(data)!
                }
            } else if self.elementName == "Longitude" {
                if routeAdded {
                    stopLong = Double(data)!
                } else {
                    long = Double(data)!
                }
            }
        }
        
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if shapes.count > shapeCount {
            print(shapes.count)
            busMaps.append(BusMap())
            manager.fetchRouteCoords(shapeID: shapes[shapeCount])
            shapeCount += 1
        } else {
            if !routeAdded {
                DispatchQueue.main.async(execute: {
                    self.routeAdded = true
                    self.busStopsManager.fetchBusStops(routeID: self.bus!.id, direction: self.direction!)
                    self.addRoute()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.addBusStopMarker()
                })
            }
        }
        
        didFinishShapes = true
    }
}
