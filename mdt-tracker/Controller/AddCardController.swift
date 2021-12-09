//
//  AddCardController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/16/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class AddCardController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var addCardButton: UIButton!
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    let cardManager = CardManager()
    var delegate: CardController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCardButton.layer.cornerRadius = 10.0
        cardNumberTextField.delegate = self
        nicknameTextField.delegate = self
        
        let viewTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        view.addGestureRecognizer(viewTap)
    }
    
    @objc func dismissKeyboard() {
        cardNumberTextField.endEditing(true)
        nicknameTextField.endEditing(true)
    }
    
    @IBAction func addCardPressed(_ sender: Any) {
        let card = Card(name: nicknameTextField.text, num: cardNumberTextField.text!.replacingOccurrences(of: " ", with: ""), value: "$0.00")
        
        if card.num!.count == 20 {
            cardManager.addCard(card: card)
            delegate?.updateCards(refresh: true)
            self.dismiss(animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Invalid number", message: "The Easy Card number you entered is invalid", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
