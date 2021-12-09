//
//  ViewController.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 1/31/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class FavoritesController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var favoritesTable: UITableView!
    @IBOutlet weak var favoritesLabel: UILabel!
    
    var favorites = [Favorite]()
    let cellIdentifier = "BusesTableViewCellReuseIdentifier"
    var favoritesManager = FavoritesManager()
    var cardManager = CardManager()
    var selectedBus: Bus?
    var selectedStop: BusStop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        favoritesTable.register(UINib(nibName: "BusesTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFavorites(refresh: true)
        favoritesTable.reloadData()
    }
    
    func updateFavorites(refresh: Bool) {
        favorites = favoritesManager.retriveFavorites()
        
        if favorites.count == 0 {
            favoritesLabel.isHidden = false
        } else if refresh {
            favoritesLabel.isHidden = true
            favoritesTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favorite = favorites[indexPath.row]
        selectedStop = favorite.stop
        selectedBus = favorite.bus
        
        favoritesTable.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "favoritesSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BusesTableViewCell
        let favorite = favorites[indexPath.row]
       
        cell.busShortNameLabel.text = favorite.bus.name
        cell.busExtendedNameLabel.text = favorite.stop.stopName
        cell.busNumberLabel.text = "\(favorite.bus.id)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            success(true)
            let favorite = self.favorites[indexPath.row]
            self.favoritesManager.removeFavorite(favorite: favorite)
            self.updateFavorites(refresh: false)
            self.favoritesTable.deleteRows(at: [indexPath], with: .automatic)
        })
        
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailsController = segue.destination as! BusDetailsController
        detailsController.bus = selectedBus
        detailsController.stop = selectedStop
    }
}

