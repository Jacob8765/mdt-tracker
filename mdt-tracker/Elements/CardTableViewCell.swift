//
//  CardTableViewCell.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 2/13/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class CardTableViewCell: UITableViewCell {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardName: UILabel!
    @IBOutlet weak var cardNum: UILabel!
    @IBOutlet weak var cardValue: UILabel!
}
