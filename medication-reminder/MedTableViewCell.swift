//
//  MedTableViewCell.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-08.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit

protocol CompleteMed: class {
    func finishMed(_ cellView: MedTableViewCell) -> Void
}

class MedTableViewCell: UITableViewCell {

    @IBOutlet weak var containerV: UIView!
    @IBOutlet weak var medName: UILabel!
    @IBOutlet weak var dosage: UILabel!
    @IBOutlet weak var timeToTake: UILabel!
    @IBOutlet weak var completedButton: UIButton!
    
    public weak var finishMedicine: CompleteMed?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.completedButton.layer.cornerRadius = 8.0
     //   self.completedButton.layer.borderWidth = 1.0
     //   self.completedButton.layer.borderColor = UIColor.gray.withAlphaComponent(0.6).cgColor
        self.completedButton.layer.masksToBounds = true
        
        self.completedButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        
        self.containerV.layer.cornerRadius = 6.0
        self.containerV.layer.masksToBounds = true
        
        self.completedButton.addTarget(self, action: #selector(MedTableViewCell.completePressed), for: .touchUpInside)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func completePressed() {
        if let delegate = self.finishMedicine {
            delegate.finishMed(self)
        }
    }

}
