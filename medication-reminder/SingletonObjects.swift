//
//  SingletonObjects.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-10.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation
import UIKit
import Moya
import Alamofire
import RxSwift
import UserNotifications

let netWorkProvider = RxMoyaProvider<MedAPI>()
let disposeBag = DisposeBag()
let center = UNUserNotificationCenter.current()
