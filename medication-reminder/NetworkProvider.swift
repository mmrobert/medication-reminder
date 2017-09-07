//
//  NetworkProvider.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation
import UIKit
import Moya
import Alamofire
import RxSwift

let netWorkProvider = RxMoyaProvider<MedAPI>()
let disposeBag = DisposeBag()

