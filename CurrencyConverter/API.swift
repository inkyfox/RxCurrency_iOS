//
//  API.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 25..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Alamofire
import RxAlamofire
import SwiftyJSON

enum API {
    
    static let `default`: APIServer = DefaultAPIServer()
    
    case latest
    
}

protocol APIServer {
    var sessionManager: SessionManager { get }
    
    var updateInterval: TimeInterval { get }
    
    func method(_ api: API) -> HTTPMethod
    
    func url(_ api: API) -> String
}

extension APIServer {
    
    func request(_ api: API, parameters: [String : AnyObject]? = nil) -> Observable<SwiftyJSON.JSON> {
        return sessionManager.rx.responseJSON(method(api), url(api), parameters: parameters)
            .map { SwiftyJSON.JSON($1) }
            .do(onNext: { print("\(NSDate()) Reloaded: \($0["rates"].count) items") })
    }

}

struct DefaultAPIServer : APIServer {
    
    private let baseServerURL = "https://api.fixer.io"
    
    var updateInterval: TimeInterval { return 24 * 60 * 60 }
    
    let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return SessionManager(configuration: configuration)
    }()
    
    func method(_ api: API) -> HTTPMethod {
        switch api {
        case .latest: return .get
        }
    }
    
    func url(_ api: API) -> String {
        switch api {
        case .latest: return "\(baseServerURL)/latest"
        }
    }
    
}
