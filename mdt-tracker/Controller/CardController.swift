//
//  CardController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/1/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class CardController: UIViewController, UITableViewDataSource, UITableViewDelegate, XMLParserDelegate, UIApplicationDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var cardTableView: UITableView!
    @IBOutlet weak var noCardsLabel: UILabel!
    var cards = [Card]()
    let cellIdentifier = "cardCell"
    let generator = UIImpactFeedbackGenerator(style: .medium)
    var cardManager = CardManager()
    var elementName = ""
    var selectedCard: Card?
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardManager.delegate = self
        //UserDefaults.standard.set([], forKey: "cards")
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        refreshControl.addTarget(self, action: #selector(updateCards), for: UIControl.Event.valueChanged)
        cardTableView.refreshControl = refreshControl
        setupLongPressGesture()
        //cards.append(Card(name: "Jake", num: "01611434953097112329", value: "$0.00"))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCards(refresh: true)
    }
    
    @objc func updateCards(refresh: Bool = false) {
         cards = cardManager.retriveCards()
         
         if cards.count == 0 {
             cardTableView.isHidden = true
             noCardsLabel.isHidden = false
         } else if refresh {
             cardTableView.isHidden = false
             noCardsLabel.isHidden = true
             cardTableView.reloadData()
         }
        
        if cards.count > 0 {
            cardManager.fetchCardBalance(cards: cards)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "addCard", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CardTableViewCell
        let card = cards[indexPath.row]
        
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.cardName.text = card.name
        cell.cardNum.text = cardManager.formatNumber(num: card.num!)
        cell.cardValue.text = card.value
        cell.cardView.layer.cornerRadius = 10.0
        
        return cell
    }
    
    func setupLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        self.cardTableView.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.cardTableView)
            if let indexPath = cardTableView.indexPathForRow(at: touchPoint) {
                deleteCardView(indexPath)
            }
        }
    }
        
    func deleteCardView(_ indexPath: IndexPath) {
        generator.impactOccurred()
        selectedCard = cards[indexPath.row]
        
        let alert = UIAlertController(title: "Delete card", message: "Do you want to remove \"\(selectedCard?.name ?? "")\"", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in
            self.cardManager.removeCard(card: self.selectedCard!)
            self.updateCards(refresh: true)
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true)
        //performSegue(withIdentifier: "cardDetailsSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cardDetailsSegue" {
            let detailsController = segue.destination as! CardDetailsController
            detailsController.delegate = self
            detailsController.card = selectedCard
        } else {
            let addCardController = segue.destination as! AddCardController
            addCardController.delegate = self
        }
    }
    
    
    
    //XML parsing
    var cardNumber: String = ""
    var balance: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "response" {
            cardNumber = ""
            balance = ""
        }
        
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "response" {
            for i in 0..<cards.count {
                if cards[i].num == cardNumber {
                    cards[i].value = balance
                    return
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.newlines)
        
        if (!data.isEmpty) {
            if self.elementName == "easy_card_number" {
                print(data)
                cardNumber = data
            } else if self.elementName == "remaining_value" {
                print(data)
                balance = data
            }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async(execute: {
            self.cardManager.saveCards(cards: self.cards)
            self.refreshControl.endRefreshing()
            self.cardTableView.reloadData()
        })
    }
}
