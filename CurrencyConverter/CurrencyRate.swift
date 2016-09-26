//
//  CurrencyRate.swift
//  CurrencyConverter
//
//  Created by indy on 2016. 9. 26..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation

struct CurrencyRate {
    fileprivate static let eurCode = "EUR"
    
    fileprivate static let defaultLocaleTable: [String : String] = [
        "AUD" : "en_AU",
        "BGN" : "bg_BG",
        "BRL" : "pt_BR",
        "CAD" : "en_CA",
        "CHF" : "gsw_CH",
        "CNY" : "zh_Hans_CN",
        "CZK" : "cs_CZ",
        "DKK" : "da_DK",
        "GBP" : "en_GB",
        "HKD" : "zh_Hans_HK",
        "HRK" : "hr_HR",
        "HUF" : "hu_HU",
        "IDR" : "id_ID",
        "ILS" : "he_IL",
        "INR" : "hi_IN",
        "JPY" : "ja_JP",
        "KRW" : "ko_KR",
        "MXN" : "es_MX",
        "MYR" : "ms_MY",
        "NOK" : "nb_NO",
        "NZD" : "en_NZ",
        "PHP" : "fil_PH",
        "PLN" : "pl_PL",
        "RON" : "ro_RO",
        "RUB" : "ru_RU",
        "SEK" : "sv_SE",
        "SGD" : "en_SG",
        "THB" : "th_TH",
        "TRY" : "tr_TR",
        "USD" : "en_US",
        "ZAR" : "en_ZA"
    ]

    fileprivate static let localeTable: [String : String] = buildLocaleTable()
    
    let currency: Currency
    let rate: Double
    
    init(currency: Currency, rate: Double) {
        self.currency = currency
        self.rate = rate
    }
    
    init(currencyCode: String, rate: Double) {
        self.init(
            currency: Currency(
                code: currencyCode,
                flag: CurrencyRate.flag(currencyCode),
                name: CurrencyRate.currencyName(currencyCode),
                symbol: CurrencyRate.currencySymbol(currencyCode),
                countryName: CurrencyRate.countryName(currencyCode)),
            rate: rate
        )
    }
}

extension CurrencyRate {
    fileprivate static func buildLocaleTable() -> [String : String]{
        var table: [String : String] = defaultLocaleTable
        
        for code in Locale.availableIdentifiers {
            let locale = Locale(identifier: code)
            guard let currencyCode = locale.currencyCode else { continue }
            if table[currencyCode] == nil {
                table[currencyCode] = code
            }
        }
        
        return table
    }

    fileprivate static func locale(_ currencyCode: String) -> Locale? {
        if currencyCode == eurCode { return nil }
        guard let identifier = localeTable[currencyCode] else { return nil }
        return Locale(identifier: identifier)
    }
    
    fileprivate static func flag(_ currencyCode: String) -> String {
        if currencyCode == eurCode { return "🇪🇺" }
        guard let regionCode = locale(currencyCode)?.regionCode else { return "" }
        var string = ""
        for u in regionCode.unicodeScalars {
            guard let c = UnicodeScalar(127397 + u.value) else { return "" }
            string.append(String(c))
        }
        return string
    }
    
    fileprivate static func countryName(_ currencyCode: String) -> String {
        if currencyCode == eurCode { return "EU" }
        guard let regionCode = locale(currencyCode)?.regionCode else { return "" }
        return Locale.current.localizedString(forRegionCode: regionCode) ?? ""
    }
    
    fileprivate static func currencySymbol(_ currencyCode: String) -> String {
        if currencyCode == eurCode { return "€" }
        return locale(currencyCode)?.currencySymbol ?? ""
    }
    
    fileprivate static func currencyName(_ currencyCode: String) -> String {
        return Locale.current.localizedString(forCurrencyCode: currencyCode) ?? ""
    }
}
