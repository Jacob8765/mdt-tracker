//
//  CardDetailsController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/17/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class CardDetailsController: UIViewController {
    var delegate: CardController?
    var card: Card?
    var cardManager = CardManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func removeCardPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to remove \"\(card?.name ?? "")\"", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.cardManager.removeCard(card: self.card!)
            self.delegate?.updateCards(refresh: true)
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true)
    }
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //TODO: implement the history table view stuff...
}
