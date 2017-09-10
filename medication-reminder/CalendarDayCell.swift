//
//  CalendarDayCell.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit
import Foundation

let cellColorDefault = UIColor(white: 0.0, alpha: 0.1)
let cellColorToday = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.3)
let borderColor = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.8)

class CalendarDayCell: UICollectionViewCell {
    
    lazy var pBackgroundView : UIView = {
        let vFrame = self.frame.insetBy(dx: 3.0, dy: 3.0)
        let view: UIView = UIView(frame: vFrame)
        view.layer.cornerRadius = 4.0
        view.layer.borderColor = borderColor.cgColor
        view.layer.borderWidth = 0.0
        view.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
        view.backgroundColor = cellColorDefault
        view.layer.masksToBounds = true
        
        return view
    }()
    
    lazy var textLabel : UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.textColor = UIColor.darkGray
        lbl.font = UIFont(name: "Helvetica", size: 16.0)
        
        return lbl
    }()
    
    override var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.pBackgroundView.layer.borderWidth = 2.0
            }
            else {
                self.pBackgroundView.layer.borderWidth = 0.0
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //  self.baseInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    /*
     override func awakeFromNib() {
     super.awakeFromNib()
     self.baseInit()
     }
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        self.baseInit()
    }
    
    private func baseInit() {
        
        self.addSubview(self.pBackgroundView)
        
        self.textLabel.frame = self.bounds
        self.addSubview(self.textLabel)
        
    }
}

