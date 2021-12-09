//
//  FavoritesManager.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/8/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct FavoritesManager {
    let defaults = UserDefaults.standard
    
    func retriveFavorites() -> [Favorite] {
        if let data = defaults.data(forKey: "favorites") {
                let array = try! PropertyListDecoder().decode([Favorite].self, from: data)
                return array
            
        } else {
            return []
        }
    }
    
    func addFavorite(favorite: Favorite) {
        if let data = defaults.data(forKey: "favorites") {
            var array = try! PropertyListDecoder().decode([Favorite].self, from: data)
            array.append(favorite)
            saveFavorites(favorites: array)
        } else {
            saveFavorites(favorites: [favorite])
        }
    }
    
    func saveFavorites(favorites: [Favorite]) {
        print(favorites)
        if let data = try? PropertyListEncoder().encode(favorites) {
            defaults.set(data, forKey: "favorites")
        }
    }
    
    func removeFavorite(favorite: Favorite) {
        if let data = defaults.data(forKey: "favorites") {
            var array = try! PropertyListDecoder().decode([Favorite].self, from: data)
            
            for i in 0..<array.count {
                if array[i].bus.id == favorite.bus.id && array[i].stop.direction == favorite.stop.direction && array[i].stop.stopID == favorite.stop.stopID {
                    array.remove(at: i)
                    break;
                }
            }
            
            saveFavorites(favorites: array)
        } else {
            saveFavorites(favorites: [favorite])
        }
    }
    
    func containsBus(routeID: Int, direction: String, stopID: Int) -> Bool {
        if let data = defaults.data(forKey: "favorites") {
            let array = try! PropertyListDecoder().decode([Favorite].self, from: data)
            print(array)
            
            for item in array {
                if item.bus.id == routeID && item.stop.direction == direction && item.stop.stopID == stopID {
                    return true
                }
            }
        }
        
        return false
    }
}
