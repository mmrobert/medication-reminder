//
//  MedAPI.swift
//  medication-reminder
//
//  Created by boqian cheng on 2017-09-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import Moya

public enum MedAPI {
    case index
    case show(id: String)
    case create
    case update(id: String)
    case destroy(id: String)
}

extension MedAPI: TargetType {
    
    public var baseURL: URL {
        return URL(string: "http://localhost:9000/api/medications")!
    }
    
    public var path: String {
        switch self {
        case .index:
            return ""
        case .show(let id):
            return "/\(id)"
        case .create:
            return ""
        case .update(let id):
            return "/\(id)"
        case .destroy(let id):
            return "/\(id)"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .index, .show:
            return .get
        case .create:
            return .post
        case .update:
            return .put
        case .destroy:
            return .delete
        }
    }
    
    public var parameters: [String: Any]? {
        return nil
    }
    
    public var parameterEncoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    public var sampleData: Data {
        return "Medicine test.".data(using: String.Encoding.utf8)!
        
    }
    
    public var task: Task {
        return .request
    }
}


