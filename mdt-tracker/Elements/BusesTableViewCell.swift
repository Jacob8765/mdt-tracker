//
//  BusesTableViewCell.swift
//  mdt-tracker
//
//  Created by Jacob Schuster on 8/3/20.
//  Copyright © 2020 Jacob Schuster. All rights reserved.
//

import UIKit

class BusesTableViewCell: UITableViewCell {
    @IBOutlet weak var busNumberLabel: UILabel!
    @IBOutlet weak var busShortNameLabel: UILabel!
    @IBOutlet weak var busExtendedNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        busNumberLabel.clipsToBounds = true
        busNumberLabel.layer.cornerRadius = 3.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
