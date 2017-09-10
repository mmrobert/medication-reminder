//
//  ViewController.swift
//  medication-reminder
//
//  Created by Vikas Gandhi on 2017-03-17.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Moya
import RxSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var calendarView: CalendarView!
    @IBOutlet weak var medTableView: UITableView!
    @IBOutlet weak var activityIndicatorBack: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    fileprivate var medListStruct: [Medicine] = []
    fileprivate var medToday: [Medicine] = []
    fileprivate var medTodaySorted: [Medicine] = []
    
    fileprivate let calendarLocal = Calendar.current
    
    fileprivate let dateFormatString = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    fileprivate let dateFormatter = DateFormatter()
    
    public let selectedDay: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.calendarView.dataSource = self
        self.medTableView.dataSource = self
        
        self.medTableView.estimatedRowHeight = 50.0
        self.medTableView.rowHeight = UITableViewAutomaticDimension
        
        self.activityIndicatorBack.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.view.sendSubview(toBack: self.activityIndicatorBack)
        
        center.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.netWorkerLoading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.medTodaySorted.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "medListItem", for: indexPath) as! MedTableViewCell
        
        // Configure the cell...
        cell.finishMedicine = self
        
        cell.medName.text = self.medTodaySorted[indexPath.row].name
        cell.dosage.text = self.medTodaySorted[indexPath.row].dosage
        
        if let medDateStr = self.medTodaySorted[indexPath.row].time {
            self.dateFormatter.dateFormat = self.dateFormatString
            let medDate = self.dateFormatter.date(from: medDateStr)
            if let _medDate = medDate {
                self.dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm"
                cell.timeToTake.text = self.dateFormatter.string(from: _medDate)
            }
        }
        
        if !(self.medTodaySorted[indexPath.row].completed ?? false) {
            self.dateFormatter.dateFormat = self.dateFormatString
            if let dayTimeString = self.medTodaySorted[indexPath.row].time, let dayTime = self.dateFormatter.date(from: dayTimeString) {
                let now = Date()
                if let fiveMinutesAgo = self.calendarLocal.date(byAdding: .minute, value: -5, to: now), dayTime.compare(fiveMinutesAgo) == ComparisonResult.orderedAscending {
        // missed medicine
                    cell.completedButton.alpha = 1
                    cell.completedButton.isEnabled = true
                    cell.completedButton.isUserInteractionEnabled = true
                    
                    cell.containerV.backgroundColor = UIColor.red.withAlphaComponent(0.2)
                } else if let fiveMinutesAfter = self.calendarLocal.date(byAdding: .minute, value: 5, to: now), dayTime.compare(fiveMinutesAfter) == ComparisonResult.orderedDescending {
        // coming medicine
                    cell.completedButton.alpha = 0
                    cell.completedButton.isEnabled = false
                    cell.completedButton.isUserInteractionEnabled = false
                    
                    cell.containerV.backgroundColor = UIColor.yellow.withAlphaComponent(0.2)
                } else {
        // inside +- 5 minutes
                    cell.completedButton.alpha = 1
                    cell.completedButton.isEnabled = true
                    cell.completedButton.isUserInteractionEnabled = true
                    
                    cell.containerV.backgroundColor = UIColor.green.withAlphaComponent(0.2)
                }
            }
        } else {
        //  completed from server
            cell.completedButton.alpha = 0
            cell.completedButton.isEnabled = false
            cell.completedButton.isUserInteractionEnabled = false
            cell.containerV.backgroundColor = UIColor.white
        }
        
        return cell

    }
    
    fileprivate func netWorkerLoading() {
        self.view.bringSubview(toFront: self.activityIndicatorBack)
        self.activityIndicator.startAnimating()
        netWorkProvider.request(.index).subscribe { [unowned self] event in
            self.activityIndicator.stopAnimating()
            self.view.sendSubview(toBack: self.activityIndicatorBack)
            switch event {
            case .next(let response):
                do {
                    if let jsonArray = try response.mapJSON() as? Array<Any> {
                        if jsonArray.count > 0 {
                            for medJSON: [String : Any] in jsonArray as! [[String : Any]] {
                                let medStruct = Medicine(object: medJSON)
                                self.medListStruct.append(medStruct)
                            }
                            
                            self.medForDay(selectedDate: self.selectedDay)
                            self.sortingMedByTime()
                            self.addAllReminders(meds: self.medTodaySorted)
                            self.medTableView.reloadData()
                        }
                    }
                } catch {
                    debugPrint("Mapping Error: \(error.localizedDescription)")
                }
            case .error(let error):
                debugPrint("Mapping Error: \(error.localizedDescription)")
            default:
                break
            }
            }.addDisposableTo(disposeBag)
    }
    
    fileprivate func medForDay(selectedDate: Date) {
        self.dateFormatter.dateFormat = self.dateFormatString
        let selectedDateComp = self.calendarLocal.dateComponents([.year, .month, .day], from: selectedDate)
        for med in self.medListStruct {
            if let medDateStr = med.time {
                let medDate = self.dateFormatter.date(from: medDateStr)
                if let _medDate = medDate {
                    let medDateComp = self.calendarLocal.dateComponents([.year, .month, .day], from: _medDate)
                    if selectedDateComp.year == medDateComp.year && selectedDateComp.month == medDateComp.month && selectedDateComp.day == medDateComp.day {
                        self.medToday.append(med)
                    }
                }
            }
            
        }
    }
    
    func sortingMedByTime() {
        self.dateFormatter.dateFormat = self.dateFormatString
        var medTimeArray: [Date] = []
        for med in self.medToday {
            if let medDateStr = med.time {
                let medDate = self.dateFormatter.date(from: medDateStr)
                if let _medDate = medDate {
                    medTimeArray.append(_medDate)
                }
            }
        }
        let sortedArray = medTimeArray.sorted(by: { $0.compare($1) == .orderedAscending })
        for time in sortedArray {
            for med in self.medToday {
                if let medDateStr = med.time {
                    let medDate = self.dateFormatter.date(from: medDateStr)
                    if medDate == time {
                        self.medTodaySorted.append(med)
                    }
                }
            }
        }
    }
    
    fileprivate func addAllReminders(meds: [Medicine]) {
        for med in meds {
            if !(med.completed ?? false) {
                self.addReminder_minus_5(med: med)
                self.addReminder(med: med)
                self.addReminder_plus_5(med: med)
            }
        }
    }

    fileprivate func addReminder_minus_5(med: Medicine) {
        
        self.dateFormatter.dateFormat = self.dateFormatString
        let calendarUnit: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        
        guard let dayTimeString = med.time, let dayTime = self.dateFormatter.date(from: dayTimeString) else {
            return
        }
        guard let fiveMinutesAgo = self.calendarLocal.date(byAdding: .minute, value: -5, to: dayTime) else {
            return
        }
        
        // if time is earlier, don't add alarm
        let now = Date()
        if fiveMinutesAgo.compare(now) == ComparisonResult.orderedAscending {
            return
        }
        
        let dateComponents =  self.calendarLocal.dateComponents(calendarUnit, from: fiveMinutesAgo)
        
        let content = UNMutableNotificationContent()
        content.title = "Don't forget medicine!"
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm"
        content.body = self.dateFormatter.string(from: dayTime)
   //     content.sound = UNNotificationSound.default()
        content.sound = nil
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = (med._id != nil) ? med._id! + "-5" : "11111"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
        })
    }
    
    fileprivate func addReminder(med: Medicine) {
        
        self.dateFormatter.dateFormat = self.dateFormatString
        let calendarUnit: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        
        guard let dayTimeString = med.time, let dayTime = self.dateFormatter.date(from: dayTimeString) else {
            return
        }
        
        // if time is earlier, don't add alarm
        let now = Date()
        if dayTime.compare(now) == ComparisonResult.orderedAscending {
            return
        }
        
        let dateComponents =  self.calendarLocal.dateComponents(calendarUnit, from: dayTime)
        
        let content = UNMutableNotificationContent()
        content.title = "Time for medicine!"
        let nameStr = med.name ?? ""
        let dosageStr = med.dosage ?? ""
        content.body = nameStr + " (\(dosageStr))"
        content.sound = UNNotificationSound(named: "chime_bell_ding.wav")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = med._id ?? "11111"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
        })
    }
    
    fileprivate func addReminder_plus_5(med: Medicine) {
        
        self.dateFormatter.dateFormat = self.dateFormatString
        let calendarUnit: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        
        guard let dayTimeString = med.time, let dayTime = self.dateFormatter.date(from: dayTimeString) else {
            return
        }
        guard let fiveMinutesAfter = self.calendarLocal.date(byAdding: .minute, value: 5, to: dayTime) else {
            return
        }
        
        // if time is earlier, don't add alarm
        let now = Date()
        if fiveMinutesAfter.compare(now) == ComparisonResult.orderedAscending {
            return
        }
        
        let dateComponents =  self.calendarLocal.dateComponents(calendarUnit, from: fiveMinutesAfter)
        
        let content = UNMutableNotificationContent()
        content.title = "Don't forget medicine!"
        content.body = "Time passed!"
        content.sound = UNNotificationSound(named: "beep-8.wav")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = (med._id != nil) ? med._id! + "+5" : "11111"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
        })
    }
/*
    func addReminder_test() {
        
        self.dateFormatter.dateFormat = self.dateFormatString
        let calendarUnit: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        
        let now = Date()
        guard let fiveMinutesAfter = self.calendarLocal.date(byAdding: .minute, value: 2, to: now) else {
            return
        }
        
        let dateComponents =  self.calendarLocal.dateComponents(calendarUnit, from: fiveMinutesAfter)
        
        let content = UNMutableNotificationContent()
        content.title = "Don't forget medicine!"
        content.body = "9999-66-55-CH"
        content.sound = UNNotificationSound(named: "beep-8.wav")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = "11111"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
        })
    }
*/
    func presentAlert(aTitle: String?, withMsg: String?, confirmTitle: String?) {
        
        typealias Handler = (UIAlertAction?) -> Void
        
        let alert = UIAlertController(title: aTitle, message: withMsg, preferredStyle: .alert)
        let okAct = UIAlertAction(title: confirmTitle, style: .default, handler: nil)
        alert.addAction(okAct)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    deinit {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
    
}

extension ViewController: CalendarViewDataSource {
    
    func startDate() -> Date? {
        
        let today = Date()
        let eightMonthsAgo = self.calendarView.calendar.date(byAdding: .month, value: -8, to: today)
        
        return eightMonthsAgo
    }
    
    func endDate() -> Date? {
        
        let today = Date()
        let fiveYearsFromNow = self.calendarView.calendar.date(byAdding: .year, value: 5, to: today)
        
        return fiveYearsFromNow
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound])
        let bodyStr = notification.request.content.body
        self.presentAlert(aTitle: "Time for medicine!", withMsg: bodyStr, confirmTitle: "OK")
        self.medTableView.reloadData()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

extension ViewController: CompleteMed {
    
    func finishMed(_ cellView: MedTableViewCell) {
        
        center.removeAllDeliveredNotifications()
        self.dateFormatter.dateFormat = self.dateFormatString
        let pressedRow = self.medTableView.indexPathForRow(at: cellView.center)
        if let row = pressedRow?.row {
            let med = self.medTodaySorted[row]
            
            if let dayTimeString = med.time, let dayTime = self.dateFormatter.date(from: dayTimeString) {
                let now = Date()
                if now.compare(dayTime) == ComparisonResult.orderedAscending {
            // removing further alarm for this medicine
                    let identifier = med._id ?? "11111"
                    let identifier5 = (med._id != nil) ? med._id! + "+5" : "11111"
                    center.removePendingNotificationRequests(withIdentifiers: [identifier, identifier5])
                    
                } else if let fiveMinutesAfter = self.calendarLocal.date(byAdding: .minute, value: 5, to: dayTime), now.compare(fiveMinutesAfter) == ComparisonResult.orderedAscending {
            // removing further alarm for this medicine
                    let identifier5 = (med._id != nil) ? med._id! + "+5" : "11111"
                    center.removePendingNotificationRequests(withIdentifiers: [identifier5])
                }
            }
            
            if let idStr = med._id {
                self.netWorkerDestroy(id: idStr, positionIndex: row)
            }
        }
    }
    
    func netWorkerDestroy(id: String, positionIndex: Int) {
        self.view.bringSubview(toFront: self.activityIndicatorBack)
        self.activityIndicator.startAnimating()
        netWorkProvider.request(.destroy(id: id)).subscribe { [unowned self] event in
            self.activityIndicator.stopAnimating()
            self.view.sendSubview(toBack: self.activityIndicatorBack)
            switch event {
            case .next(let response):
                if let responseStr = try? response.mapString() {
                    print(responseStr)
                }
                self.medTodaySorted.remove(at: positionIndex)
                self.medTableView.reloadData()
            case .error(let error):
                debugPrint("Mapping Error: \(error.localizedDescription)")
            default:
                break
            }
            }.addDisposableTo(disposeBag)
    }
}


