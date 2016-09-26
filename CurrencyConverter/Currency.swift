//
//  Currency.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 22..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation

struct Currency {
    let code: String
    let flag: String
    let name: String
    let symbol: String
    let countryName: String
    
    static let null: Currency = Currency(code: "", flag: "", name: "", symbol: "", countryName: "")
}

extension Currency: Hashable {
    var hashValue: Int { return code.hashValue }
}

func ==(lhs: Currency, rhs: Currency) -> Bool {
    return lhs.code == rhs.code
}

extension Currency: CustomStringConvertible {
    var description: String { return "(\(code) \(name))" }
}
