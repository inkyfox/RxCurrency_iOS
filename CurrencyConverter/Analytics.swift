//
//  Analytics.swift
//  CurrencyConverter
//
//  Created by indy on 2016. 9. 27..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import FirebaseAnalytics

enum Analytics {
    
    case load
    case loadSuccess(elapsed: Double)
    case loadFailed(elapsed: Double)
    
    case buttonReload
    case periodicReload(elapsed: Double)
    case buttonSwap
    
    case slide(viewID: String, value: Double, currency: Currency)
    case buttonNumber(viewID: String, value: Double, currency: Currency)
    
    case currencySelector(viewID: String)
    case currencyChanged(viewID: String, from: Currency, to: Currency)
    
    var name: String {
        switch self {
        case .load: return "load_try"
        case .loadSuccess: return "load_success"
        case .loadFailed: return "load_failed"

        case .buttonReload: return "action_loadButton"
        case .periodicReload: return "action_periodicReload"
        case .buttonSwap: return "action_swapButton"

        case .slide: return "action_slide"
        case .buttonNumber: return "action_numberButtons"
            
        case .currencySelector: return "action_currencySelector"
        case .currencyChanged: return "action_currencyChanged"
        }
    }
    
    var parameters: [String: NSObject]? {
        switch self {
        case .loadSuccess(let elapsed):
            return ["elapsed" : NSNumber(value: elapsed)]
        case .loadFailed(let elapsed):
            return ["elapsed" : NSNumber(value: elapsed)]
        case .periodicReload(let elapsed):
            return ["elapsed" : NSNumber(value: elapsed)]

        case .slide(let viewID, let value, let currency):
            return ["view" : NSString(string: viewID), "value" : NSNumber(value: value), "currency" : NSString(string: currency.code)]
        case .buttonNumber(let viewID, let value, let currency):
            return ["view" : NSString(string: viewID), "value" : NSNumber(value: value), "currency" : NSString(string: currency.code)]

        case .currencySelector(let viewID):
            return ["view" : NSString(string: viewID)]
        case .currencyChanged(let viewID, let from, let to):
            return ["view" : NSString(string: viewID), "from" : NSString(string: from.code), "to" : NSString(string: to.code)]

        default:
            return nil
        }
    }
}

extension Analytics {
    
    func send(with parameters: [String : NSObject]? = nil) {
        FIRAnalytics.logEvent(withName: self.name, parameters: parameters)
    }
    
}
