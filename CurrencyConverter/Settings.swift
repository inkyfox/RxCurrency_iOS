//
//  Settings.swift
//  CurrencyConverter
//
//  Created by indy on 2016. 9. 26..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

fileprivate enum Key: String {
    case rateUpdatedTime, rateDate, rates
    case upperCurrency, lowerCurrency, lowerNumber
    case adRemoved
}

class Settings : ReactiveCompatible {
    
    static let instance = Settings()
    
    private var storage: UserDefaults = UserDefaults.standard
    
    private init() {

    }
    
    var rateUpdatedTime: TimeInterval? {
        get { return storage.double(forKey: Key.rateUpdatedTime.rawValue) }
        set { storage.set(newValue, forKey: Key.rateUpdatedTime.rawValue) }
    }

    var rateDate: Date? {
        get { return storage.object(forKey: Key.rateDate.rawValue)  as? Date }
        set { storage.set(newValue, forKey: Key.rateDate.rawValue) }
    }

    var rates: [String : CurrencyRate]? {
        get {
            guard let dic = storage.dictionary(forKey: Key.rates.rawValue) as? [String : Double] else { return nil }
            var rates: [String : CurrencyRate] = [:]
            for (code, rate) in dic {
                rates[code] = CurrencyRate(currencyCode: code, rate: rate)
            }
            return rates
        }
        
        set {
            guard let rates = newValue else {
                storage.set(nil, forKey: Key.rates.rawValue)
                return
            }
            var dic: [String : Double] = [:]
            for (key, value) in rates { dic[key] = value.rate }
            storage.set(dic, forKey: Key.rates.rawValue)
        }
    }
    
    var upperCurrency: Currency? {
        get { return CurrencyFactory.instance.currency(ofCode: storage.string(forKey: Key.upperCurrency.rawValue)) }
        set { storage.set(newValue?.code, forKey: Key.upperCurrency.rawValue) }

    }
    
    var lowerCurrency: Currency? {
        get { return CurrencyFactory.instance.currency(ofCode: storage.string(forKey: Key.lowerCurrency.rawValue)) }
        set { storage.set(newValue?.code, forKey: Key.lowerCurrency.rawValue) }
    }
    
    var lowerNumber: Double? {
        get { return storage.double(forKey: Key.lowerNumber.rawValue) }
        set { storage.set(newValue, forKey: Key.lowerNumber.rawValue) }
    }

    var adRemoved: Bool? {
        get { return storage.bool(forKey: Key.adRemoved.rawValue) }
        set { storage.set(newValue, forKey: Key.adRemoved.rawValue) }
    }

    func synchronize() {
        storage.synchronize()
    }
    
}

extension Reactive where Base : Settings {
    
    var upperCurrency: AnyObserver<Currency> {
        return UIBindingObserver(UIElement: base) { setttings, currency in
              setttings.upperCurrency = currency
            }.asObserver()
    }

    var lowerCurrency: AnyObserver<Currency> {
        return UIBindingObserver(UIElement: base) { setttings, currency in
            setttings.lowerCurrency = currency
            }.asObserver()
    }
    
    var lowerNumber: AnyObserver<Double> {
        return UIBindingObserver(UIElement: base) { setttings, number in
            setttings.lowerNumber = number
            }.asObserver()
    }
    
}
