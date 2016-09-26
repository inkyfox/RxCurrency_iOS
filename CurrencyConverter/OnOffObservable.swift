//
//  OnOffObservable.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 22..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class OnOffObservable<Element>: ObservableConvertibleType {
    
    var off: Bool = false
    
    private var observable: Observable<Element>
    
    init(_ observable: Observable<Element>, off: Bool = false) {
        self.observable = observable
        self.off = off
    }
    
    func asObservable() -> Observable<Element> {
        return self.observable.filter { [weak self] _ in !(self?.off ?? true) }
    }
}
