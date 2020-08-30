//
//  MedDataModel.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation
import Marshal

struct Medicine: Unmarshaling {
    var _id: String?
    var name: String?
    var dosage: String?
    var time: String?
    var completed: Bool?
    var d: CMFDates?
    
    init(object: MarshaledObject) {
        _id = try? object.value(for: "_id")
        name = try? object.value(for: "name")
        dosage = try? object.value(for: "dosage")
        time = try? object.value(for: "time")
        completed = try? object.value(for: "completed")
        d = try? object.value(for: "d")
    }
}

extension Medicine: Marshaling {
    func marshaled() -> [String:Any] {
        let dInitial: [String:Any] = [
            "c" : "",
            "m" : "",
            "f" : ""
        ]
        
        return [
            "id" : _id ?? "",
            "name" : name ?? "",
            "dosage" : dosage ?? "",
            "time" : time ?? "",
            "completed" : completed ?? false,
            "d" : d != nil ? d!.marshaled() : dInitial,
        ]
    }
}

struct CMFDates: Unmarshaling {
    var c: String?
    var m: String?
    var f: String?
    
    init(object: MarshaledObject) {
        c = try? object.value(for: "c")
        m = try? object.value(for: "m")
        f = try? object.value(for: "f")
    }
}

extension CMFDates: Marshaling {
    func marshaled() -> [String: Any] {
        return [
            "c" : c ?? "",
            "m" : m ?? "",
            "f" : f ?? ""
        ]
    }
}

