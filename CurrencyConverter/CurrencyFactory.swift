//
//  CurrencyFactory.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 23..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxCocoa
import RxSwift


class CurrencyFactory: ReactiveCompatible {
    
    static let instance = CurrencyFactory()
    
    var updatedTime: TimeInterval? = nil
    
    fileprivate let rateDate = Variable<Date?>(nil)
    
    
    fileprivate var rates: Variable<[String : CurrencyRate]> = Variable([:])

    private init() {
        restore()
    }

    func contains(currencyCode: String) -> Bool {
        return rates.value[currencyCode] != nil
    }
    
    func currency(ofLocale locale: Locale) -> Currency? {
        guard let code = locale.currencyCode else { return nil }
        return currency(ofCode: code)
    }
    
    func currency(ofCode codeOptional: String?) -> Currency? {
        guard let code = codeOptional else { return nil }
        return rates.value[code]?.currency
    }

    var firstCurrency: Currency? {
        return rates.value.sorted { $0.0 < $1.0 }.first?.value.currency
    }

    func convert(number: Double, from: Currency, to: Currency) -> Double {
        guard let fromRate = rates.value[from.code]?.rate,
            let toRate = rates.value[to.code]?.rate,
            fromRate > 0 && toRate > 0 else { return 0 }
        
        return number * toRate / fromRate
    }

}

extension CurrencyFactory {

    fileprivate func restore() {
        guard let ratesValue = Settings.instance.rates else { return }
        
        updatedTime = Settings.instance.rateUpdatedTime
        rateDate.value = Settings.instance.rateDate
        rates.value = ratesValue
    }
    
    fileprivate func store() {
        Settings.instance.rateUpdatedTime = updatedTime
        Settings.instance.rateDate = rateDate.value
        Settings.instance.rates = rates.value
        Settings.instance.synchronize()
    }
    
}

extension Reactive where Base: CurrencyFactory {
    
    var currencies: Observable<[Currency]> {
        return base.rates.asObservable().filter { $0.count > 0 }.map { $0.values.map { $0.currency }.sorted(by: { $0.code < $1.code }) }
    }

    var rateDateString: Observable<String> {
        return base.rateDate.asObservable()
            .map { date in
                guard let d = date else { return "Unknown" }
                
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: d)
        }
    }
    
    func parse(json: JSON) -> Observable<Void> {
        return Observable.create { [weak base] observer in
            if let sbase = base {
                
                var rates: [String : CurrencyRate] = [:]
                
                if let code = json["base"].string {
                    rates[code] = CurrencyRate(currencyCode: code, rate: 1.0)
                }
                
                for item in json["rates"] {
                    let code = item.0
                    if let rate = item.1.number?.doubleValue {
                        rates[code] = CurrencyRate(currencyCode: code, rate: rate)
                    }
                }
                
                if rates.count > 1 {
                    sbase.rates.value = rates
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    sbase.rateDate.value = formatter.date(from: json["date"].stringValue)
                    
                    sbase.updatedTime = Date().timeIntervalSince1970
                    
                    sbase.store()
                    
                    observer.onNext()
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "CurrencyConverter", code: -1, userInfo: nil))
                }
            }
            return Disposables.create()
        }
        
        
    }
    

}
