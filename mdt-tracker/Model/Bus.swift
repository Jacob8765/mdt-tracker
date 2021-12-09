//
//  Bus.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/1/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct Bus: Codable {
    var id: Int
    var name: String
    var extendedName: String
    var direction1: String
    var direction2: String
}
