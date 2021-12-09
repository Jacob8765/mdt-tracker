//
//  CardManager.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/15/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import Foundation

struct CardManager {
    let statusUrl = "https://transitstore.miamidade.gov/extern/checkstatus"
    let cardBalanceUrl = "https://transitstore.miamidade.gov/ajax/checkcardstatus"
    let cardHistoryUrl = "https://transitstore.miamidade.gov/ajax/getcardhistory"
    weak var delegate: XMLParserDelegate?
    let defaults = UserDefaults.standard
    
    func fetchCardBalance(cards: [Card]) { // This is required because the mdt ajax apis require a session id.
        if let url = URL(string: statusUrl) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error as Any)
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if let fields = httpResponse.allHeaderFields as? [String: String] {
                        let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: (response?.url)!)
                                                
                        if cookies.count > 0 {
                            print("name: \(cookies[0].name) value: \(cookies[0].value)")
                            self.defaults.set(cookies[0].value, forKey: "sessionId")
                            
                            for card in cards {
                                self.balance(cardNum: card.num!, sessionId: cookies[0].value) //Actually fetches the balance of the cards
                            }
                        } else {
                            if let data = self.defaults.string(forKey: "sessionId") {
                                for card in cards {
                                    self.balance(cardNum: card.num!, sessionId: data)
                                }
                            }
                        }
                    }
                }
            })
            
            task.resume()
        }
    }
    
    func balance(cardNum: String, sessionId: String, shouldParse: Bool = true) {
        if let url = URL(string: cardBalanceUrl) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("ASP.NET_SessionId=\(sessionId)", forHTTPHeaderField: "cookie") // Set the session ID. this is required by the ajax api
            request.httpBody = "card_number=\(cardNum)".data(using: .utf8)
            
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error as Any)
                }
                
                if let safeData = data {
                    print(String(data: safeData, encoding: .utf8) as Any)
                    let parser = XMLParser(data: safeData)
                    parser.delegate = self.delegate!
                    parser.parse()
                }
            })
            
            task.resume()
        }
    }
    
    func formatNumber(num: String) -> String {
        var newString = ""
        
        for i in 1...num.count {
            newString += String(num[num.index(num.startIndex, offsetBy: i-1)])
            
            if i % 4 == 0 {
                newString += " "
            }
        }
        
        return newString
    }
    
    func retriveCards() -> [Card] {
        if let data = defaults.data(forKey: "cards") {
            let array = try! PropertyListDecoder().decode([Card].self, from: data)
            print(array)
            return array
        } else {
            return []
        }
    }
    
    func addCard(card: Card) {
        if let data = defaults.data(forKey: "cards") {
            var array = try! PropertyListDecoder().decode([Card].self, from: data)
            array.append(card)
            saveCards(cards: array)
        } else {
            saveCards(cards: [card])
        }
    }
    
    func saveCards(cards: [Card]) {
        if let data = try? PropertyListEncoder().encode(cards) {
            defaults.set(data, forKey: "cards")
        }
    }
    
    func removeCard(card: Card) {
        if let data = defaults.data(forKey: "cards") {
            var array = try! PropertyListDecoder().decode([Card].self, from: data)
            
            for i in 0..<array.count {
                if array[i].num == card.num {
                    array.remove(at: i)
                    break;
                }
            }
            
            saveCards(cards: array)
        } else {
            saveCards(cards: [card])
        }
    }
    
    
}
