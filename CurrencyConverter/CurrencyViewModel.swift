//
//  CurrencyViewModel.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 22..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
@testable import CurrencyConverter

struct SlideConverter {
    let maxDigitCount = 8
    private let maxNumber: Float
    
    init() {
        maxNumber = pow(Float(10), Float(maxDigitCount - 1))
    }

    func number(fromSlide slide: Float) -> Double {
        let powValue = Float(pow(slide, 8.0))
        let powNumber = powValue == 0 ? 0 : Int(powValue * maxNumber) + 1
        let digits = countDigits(powNumber)
        let divides = Int(pow(10.0, Double(max(0, digits - 3))))
        return Double((powNumber / divides) * divides)
    }
    
    func slide(fromNumber number: Double) -> Float {
        let intNumber = Int(number)
        return min(1, pow(Float(intNumber < 1 ? 0 : Float(intNumber - 1) / maxNumber), 1.0 / 8.0))
    }

    private func countDigits(_ number: Int) -> Int {
        var count = 1
        var up = 10
        while count < maxDigitCount {
            if number < up { return count }
            count += 1
            up *= 10
        }
        return count
    }
}

class CurrencyViewModel {
    
    class CurrencyModel: ReactiveCompatible {
        private let variable: Variable<Currency> = Variable(Currency.null)
        
        var currency: Currency {
            get { return variable.value }
            set { variable.value = newValue }
        }
        
        fileprivate var observable: Observable<Currency> { return variable.asObservable() }

        init() {
        }
        
        func asObservable() -> Observable<Currency> {
            return variable.asObservable()
        }
        
        func asObserver() -> AnyObserver<Currency> {
            return UIBindingObserver(UIElement: self) { model, currency in
                  model.currency = currency
                }.asObserver()
        }

    }
    
    class NumberModel: ReactiveCompatible {
        
        fileprivate let symbol: Variable<String> = Variable("")
        fileprivate let number: Variable<String> = Variable("")
        
        var stringNumber: String {
            get { return number.value }
            set {
                if Double(newValue) != nil { number.value = newValue }
                else { number.value = "" }
            }
        }
        
        var doubleNumber: Double {
            get { return Double(number.value) ?? 0 }
            set { stringNumber = newValue <= 0 ? "" : String(newValue) }
        }
        
        fileprivate var formattedNumber: Double {
            return format(number: doubleNumber)
        }
        
        var maxDigitCount: Int { return slideConverter.maxDigitCount }

        fileprivate var stringObservable: Observable<String> { return number.asObservable() }
        fileprivate var doubleObservable: Observable<Double> { return number.asObservable().map { Double($0) ?? 0 } }
        fileprivate var formattedNumberObservable: Observable<Double> { return doubleObservable.map(format) }

        fileprivate let formatter: NumberFormatter
        fileprivate let slideConverter = SlideConverter()
        
        init() {
            formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
        }
        
        fileprivate func format(number: Double) -> Double {
            let around = number + 0.005
            if around < 1 {
                return Double(Int(around * 100.0)) / 100.0
            } else {
                return Double(Int(number + 0.5))
            }
        }
        
        func append(_ str: String) {
            let n = formattedNumber
            let newValue: String
            if n < 1 {
                newValue = str
            } else {
                newValue = "\(String(Int(n)))\(str)"
            }
            number.value = newValue
        }
        
        func deleteLastDigit() {
            let value = number.value
            if value == "" { return }
            let n = formattedNumber
            number.value = n >= 10 ? String(Int(n / 10)) : ""
        }
        
        func setCurrencySymbol(symbol s: String) {
            symbol.value = s
        }
        
        func setSlide(slide: Float) {
            let intNumber = slideConverter.number(fromSlide: slide)
            number.value = intNumber <= 0 ? "" : String(intNumber)
        }
        
        func clear() {
            number.value = ""
        }
        
        func asObservable() -> Observable<Double> {
            return doubleObservable
        }
        
        func asObserver() -> AnyObserver<Double> {
            return UIBindingObserver(UIElement: self) { model, doubleNumber in
                  model.doubleNumber = doubleNumber
                }.asObserver()
        }
        
    }
    
    private let disposeBag = DisposeBag()

    var currency = CurrencyModel()
    var number = NumberModel()
    
    init() {
        currency.observable.observeOn(MainScheduler.instance)
            .map { $0.symbol }
            .bindNext(number.setCurrencySymbol)
            .addDisposableTo(disposeBag)
    }
}

extension Reactive where Base: CurrencyViewModel.CurrencyModel {
    
    var flag: Observable<String?> {
        return base.observable.map { $0.flag }
    }
    
    var countryName: Observable<String?> {
        return base.observable.map { $0.countryName }
    }
    
    var code: Observable<String?> {
        return base.observable.map { $0.code }
    }

    var name: Observable<String?> {
        return base.observable.map { $0.name }
    }

    var isEnabled: Observable<Bool> {
        return base.observable.map { $0 != Currency.null }
    }

}

extension Reactive where Base: CurrencyViewModel.NumberModel {
    
    var formattedString: Observable<String?> {
        return Observable.combineLatest(base.symbol.asObservable(), base.formattedNumberObservable) { (symbol, number) in
            self.base.formatter.maximumFractionDigits = number < 1 ? 2 : 0
            return "\(symbol)\(self.base.formatter.string(from: NSNumber(value: number)) ?? "")"
        }
    }
    
    var isNotEmpty: Observable<Bool> {
        return base.formattedNumberObservable.map { $0 != 0 }
    }
    
    var digitCount: Observable<Int> {
        return base.formattedNumberObservable.map { Int($0 + 0.5) }.map { String($0) }.map { $0.characters.count }
    }
 
    var slideValue: Observable<Float> {
        return base.doubleObservable.map(base.slideConverter.slide)
    }
    

}
