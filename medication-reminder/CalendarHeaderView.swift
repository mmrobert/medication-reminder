//
//  CalendarHeaderView.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit
import Foundation

public protocol ArrowPressed: class {
    func leftArrowTapped() -> Void
    func rightArrowTapped() -> Void
}

class CalendarHeaderView: UIView {
    
    weak var delegate: ArrowPressed?
    
    lazy var monthLabel : UILabel = {
        
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = UIFont(name: "Helvetica", size: 18.0)
        lbl.textColor = UIColor.gray
        
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        var frm = self.bounds
        frm.size.width = self.bounds.size.width - 136.0
        frm.size.height = 28.0
        
        self.monthLabel.frame = frm
        self.monthLabel.center = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
        //  self.monthLabel.text = "Aug 2017"
        
        self.addSubview(self.monthLabel)
        
        let leftArrow = self.createImgView()
        leftArrow.center = CGPoint(x: 46, y: self.bounds.size.height / 2)
        leftArrow.image = UIImage(named: "arrowleft")
        leftArrow.isUserInteractionEnabled = true
        
        let leftTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarHeaderView.leftTapAction))
        leftArrow.addGestureRecognizer(leftTapped)
        
        self.addSubview(leftArrow)
        
        let rightArrow = self.createImgView()
        rightArrow.center = CGPoint(x: self.bounds.size.width - 46, y: self.bounds.size.height / 2)
        rightArrow.image = UIImage(named: "arrowright")
        rightArrow.isUserInteractionEnabled = true
        
        let rightTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarHeaderView.rightTapAction))
        rightArrow.addGestureRecognizer(rightTapped)
        
        self.addSubview(rightArrow)
        
    }
    
    private func createImgView() -> UIImageView {
        let imgV = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        return imgV
    }
    
    func leftTapAction() {
        self.delegate?.leftArrowTapped()
    }
    
    func rightTapAction() {
        self.delegate?.rightArrowTapped()
    }
}

