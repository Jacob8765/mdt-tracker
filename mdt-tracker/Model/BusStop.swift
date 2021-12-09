//
//  BusStop.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/3/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct BusStop: Codable {
    var stopID: Int
    var stopName: String
    var direction: String
    var coords: Coords
}
