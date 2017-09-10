//
//  CalendarView.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit
import EventKit

let cellReuseIdentifier = "CalendarDayCell"
let SectionHeadReuseIdentifier = "CalendarSectionHead"

let HEADER_DEFAULT_HEIGHT : CGFloat = 40.0

let NUMBER_OF_DAYS_IN_WEEK = 7
let MAXIMUM_NUMBER_OF_ROWS = 2

protocol CalendarViewDataSource: class {
    
    func startDate() -> Date?
    func endDate() -> Date?
    
}

class CalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    weak var dataSource  : CalendarViewDataSource?
    
    let weekdayStr: [String] = Utilities.weekdayString()
    fileprivate var startDateCache : Date = Date()
    fileprivate var endDateCache : Date = Date()
    fileprivate var startOfMonthCache : Date = Date()
    fileprivate var totalWeeks: Int?
    fileprivate var monthlyWeekInfos : [Int:[Int]] = [Int:[Int]]()
    
    var todayIndexPath : IndexPath?
    var sectionDisplayed: Int?
    var firstDayOfMonthDisplay : Date?
    
    lazy var gregorian : Calendar = {
        
        var cal = Calendar(identifier: Calendar.Identifier.gregorian)
        cal.timeZone = TimeZone(abbreviation: "UTC")!
        cal.firstWeekday = 2
        
        return cal
    }()
    
    var calendar : Calendar {
        return self.gregorian
      //  return Calendar.current
    }
    
    lazy var headerView : CalendarHeaderView = {
        
        let hv = CalendarHeaderView(frame:CGRect.zero)
        hv.delegate = self
        
        return hv
        
    }()
    
    lazy var calendarView : UICollectionView = {
        
        let layout = CalendarFlowLayout()
        //    let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = self.direction;
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.isPagingEnabled = true
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = true
        
        return cv
        
    }()
    
    var direction : UICollectionViewScrollDirection = .horizontal {
        didSet {
            if let layout = self.calendarView.collectionViewLayout as? CalendarFlowLayout {
                layout.scrollDirection = direction
                self.calendarView.reloadData()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        //   self.createSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.createSubviews()
    }
    
    // MARK: Setup
    
    fileprivate func createSubviews() {
        
        self.calculateTotalWeeksAndDayIndex()
        
        self.clipsToBounds = true
        
        let heigh = self.frame.size.height - HEADER_DEFAULT_HEIGHT
        let width = self.frame.size.width
        
        let layout = self.calendarView.collectionViewLayout as! CalendarFlowLayout
        layout.itemSize = CGSize(width: width / CGFloat(NUMBER_OF_DAYS_IN_WEEK), height: heigh / CGFloat(MAXIMUM_NUMBER_OF_ROWS))
        
        self.headerView.frame = CGRect(x:0.0, y:0.0, width: width, height:HEADER_DEFAULT_HEIGHT)
        self.headerView.monthLabel.text = self.theMonthYearLbl(firstDayForMonth: self.startOfMonthCache)
        self.calendarView.frame = CGRect(x:0.0, y:HEADER_DEFAULT_HEIGHT, width: width, height: heigh)
        
        // Register Class
        self.calendarView.register(CalendarDayCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        self.addSubview(self.headerView)
        self.addSubview(self.calendarView)
        
        //    self.bringSubview(toFront: self.headerView)
        
        self.sectionDisplayed = self.todayIndexPath?.section
        let startIndexPath = IndexPath(item: 0, section: self.sectionDisplayed!)
        self.calendarView.scrollToItem(at: startIndexPath, at: .left, animated: true)
    }
    
    fileprivate func calculateTotalWeeksAndDayIndex() -> Void {
        guard let startDate = self.dataSource?.startDate(), let endDate = self.dataSource?.endDate() else {
            return
        }
        
        self.startDateCache = startDate
        self.endDateCache = endDate
        
        // check if the dates are in correct order
        
        if self.calendar.compare(startDate, to: endDate, toGranularity: .nanosecond) != ComparisonResult.orderedAscending {
            return
        }
        
        var firstDayOfStartMonth = self.calendar.dateComponents([.era, .year, .month, .day], from: self.startDateCache)
        firstDayOfStartMonth.day = 1
        
        guard let dateFromDayOneComponents = self.calendar.date(from: firstDayOfStartMonth) else {
            return
        }
        
        self.startOfMonthCache = dateFromDayOneComponents
        
        let today = Date()
        
        if  self.startOfMonthCache.compare(today) == ComparisonResult.orderedAscending &&
            self.endDateCache.compare(today) == ComparisonResult.orderedDescending {
            
            let differenceFromTodayComponents = self.calendar.dateComponents([.month], from: self.startOfMonthCache, to: today)
            
            var totalWeeksToToday: Int = 0
            if let differenceMonth = differenceFromTodayComponents.month {
                for month in 1...differenceMonth {
                    if let tempFirstDayOfMonth = self.calendar.date(byAdding: .month, value: month - 1, to: self.startOfMonthCache), let weeksOfMonth = self.calendar.range(of: .weekOfMonth, in: .month, for: tempFirstDayOfMonth)?.count {
                        totalWeeksToToday += weeksOfMonth
                    }
                }
            }
            
            let weekDayOfToday = self.calendar.dateComponents([.weekOfMonth, .weekday], from: today)
            let weekOfM = weekDayOfToday.weekOfMonth ?? 0
            let weekDayIndex = (weekDayOfToday.weekday! + 5) % 7
            
            self.todayIndexPath = IndexPath(item: weekDayIndex, section: totalWeeksToToday - 1 + weekOfM)
            
            let differenceFromEndDayComponents = self.calendar.dateComponents([.month], from: self.startOfMonthCache, to: self.endDateCache)
            var totalWeeksToEndDay: Int = 0
            //  var temp1stDayOfMonth = self.startOfMonthCache
            if let differenceMonthEndDay = differenceFromEndDayComponents.month {
                for month in 1...differenceMonthEndDay + 1 {
                    if let tempFirstDayOfMonth = self.calendar.date(byAdding: .month, value: month - 1, to: self.startOfMonthCache), let weeksOfMonth = self.calendar.range(of: .weekOfMonth, in: .month, for: tempFirstDayOfMonth)?.count {
                        self.calculateMonthlyWeekInfos(firstDateOfMonth: tempFirstDayOfMonth, weeksBefore: totalWeeksToEndDay, monthIndex: month - 1)
                        
                        totalWeeksToEndDay += weeksOfMonth
                    }
                }
            }
            
            self.totalWeeks = totalWeeksToEndDay
            
        }
    }
    
    fileprivate func calculateMonthlyWeekInfos(firstDateOfMonth: Date, weeksBefore: Int, monthIndex: Int) -> Void {
        
        let numberOfWeeksInMonth = self.calendar.range(of: .weekOfMonth, in: .month, for: firstDateOfMonth)?.count ?? 0
        
        var firstDayInWeek = firstDateOfMonth
        var firstDayShowInWeek = 1
        var lastDayShowInWeek = 1
        for theWeek in 1...numberOfWeeksInMonth {
            let firstWeekdayComp = self.calendar.dateComponents([.weekday], from: firstDayInWeek)
            let firstWeekdayIndex = (firstWeekdayComp.weekday! + 5) % 7
            let numberOfDaysInWeek = self.calendar.range(of: .day, in: .weekOfMonth, for: firstDayInWeek)?.count
            
            let lastDayInWeek = self.calendar.date(byAdding: .day, value: numberOfDaysInWeek! - 1, to: firstDayInWeek)!
            let lastWeekdayComp = self.calendar.dateComponents([.weekday], from: lastDayInWeek)
            let lastWeekdayIndex = (lastWeekdayComp.weekday! + 5) % 7
            
            lastDayShowInWeek = firstDayShowInWeek + numberOfDaysInWeek! - 1
            
            self.monthlyWeekInfos[weeksBefore + theWeek - 1] = [firstWeekdayIndex, firstDayShowInWeek, lastWeekdayIndex, lastDayShowInWeek, monthIndex]
            
            firstDayShowInWeek = lastDayShowInWeek + 1
            firstDayInWeek = self.calendar.date(byAdding: .day, value: 1, to: lastDayInWeek)!
        }
    }
    
    fileprivate func theMonthYearLbl(firstDayForMonth: Date) -> String? {
        let month = self.calendar.component(.month, from: firstDayForMonth) // get month
        let monthName = DateFormatter().monthSymbols[(month - 1) % 12] // 0 indexed array
        
        let year = self.calendar.component(.year, from: firstDayForMonth)
        
        return monthName + " " + String(year)
        
        //  print("9922-77")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return self.totalWeeks!
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7 + 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CalendarDayCell
        
        let weekInfo = self.monthlyWeekInfos[indexPath.section]
        
        if indexPath.item < 7 {
            dayCell.textLabel.text = self.weekdayStr[indexPath.item]
            dayCell.textLabel.textColor = UIColor.white
            dayCell.pBackgroundView.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
            dayCell.pBackgroundView.layer.cornerRadius = 12
            dayCell.isUserInteractionEnabled = false
        } else {
            dayCell.textLabel.textColor = UIColor.darkGray
            dayCell.pBackgroundView.layer.cornerRadius = 4
            
            if let firstWeekday = weekInfo?[0], let lastWeekday = weekInfo?[2] {
                if indexPath.item - 7 < firstWeekday {
                    dayCell.textLabel.text = ""
                    dayCell.pBackgroundView.backgroundColor = UIColor.clear
                    dayCell.isUserInteractionEnabled = false
                } else if indexPath.item - 7 > lastWeekday {
                    dayCell.textLabel.text = ""
                    dayCell.pBackgroundView.backgroundColor = UIColor.clear
                    dayCell.isUserInteractionEnabled = false
                } else {
                    let dayShowing = (weekInfo?[1])! + indexPath.item - 7 - firstWeekday
                    dayCell.textLabel.text = String(dayShowing)
                    dayCell.pBackgroundView.backgroundColor = cellColorDefault
                    dayCell.isUserInteractionEnabled = true
                }
            }
        }
        
        return dayCell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _ = self.setHeaderMonthYear()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let _ = self.setHeaderMonthYear()
    }
    
    fileprivate func setHeaderMonthYear() -> Date? {
        
        let cvbounds = self.calendarView.bounds
        
        var page : Int = 0
        
        switch self.direction {
        case .horizontal:
            page = Int(floor(self.calendarView.contentOffset.x / cvbounds.size.width))
            break
            
        case .vertical:
            page = Int(floor(self.calendarView.contentOffset.y / cvbounds.size.height))
            break
        }
        page = page > 0 ? page : 0
        
        let weekInfo = self.monthlyWeekInfos[page]
        let monthSt = weekInfo?[4]
        
        guard let firstDayOfMonth = self.calendar.date(byAdding: .month, value: monthSt!, to: self.startOfMonthCache) else {
            return nil
        }
        
        let month = self.calendar.component(.month, from: firstDayOfMonth) // get month
        let monthName = DateFormatter().monthSymbols[(month - 1) % 12] // 0 indexed array
        
        let year = self.calendar.component(.year, from: firstDayOfMonth)
        
        self.headerView.monthLabel.text = monthName + " " + String(year)
        
        self.firstDayOfMonthDisplay = firstDayOfMonth
        
        return firstDayOfMonth
    }
}

extension CalendarView: ArrowPressed {
    
    func leftArrowTapped() {
        if let _sectionDisplayed = self.sectionDisplayed, _sectionDisplayed > 0 {
            self.sectionDisplayed = self.sectionDisplayed! - 1
            let startIndexPath = IndexPath(item: 0, section: self.sectionDisplayed!)
            self.calendarView.scrollToItem(at: startIndexPath, at: .left, animated: true)
        }
    }
    
    func rightArrowTapped() {
        if let _sectionDisplayed = self.sectionDisplayed, _sectionDisplayed < self.monthlyWeekInfos.count {
            self.sectionDisplayed = self.sectionDisplayed! + 1
            let startIndexPath = IndexPath(item: 0, section: self.sectionDisplayed!)
            self.calendarView.scrollToItem(at: startIndexPath, at: .left, animated: true)
        }
    }
}

