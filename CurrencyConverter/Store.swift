//
//  Store.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 28..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import StoreKit
import RxCocoa
import RxSwift

enum Product {
    case adRemove
    
    var identifier: String {
        switch self {
        case .adRemove: return "MC_RMAD_001"
        }
    }
}

class Store : NSObject {

    static let instance = Store()
    
    fileprivate let products = Variable<[String : SKProduct]>([:])
    fileprivate let purchased = PublishSubject<SKProduct>()
    fileprivate var request: SKProductsRequest? = nil
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func loadProducts() {
        if let req = self.request { req.cancel() }
        
        let req = SKProductsRequest(productIdentifiers: Set<String>([Product.adRemove.identifier]))
        req.delegate = self

        request = req
        
        req.start()
    }
    
    func purchase(product: SKProduct) {
        SKPaymentQueue.default().add(SKPayment(product: product))
    }
    
    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func product(_ product: Product) -> SKProduct? {
        return products.value[product.identifier]
    }
}

extension Store : SKProductsRequestDelegate {
    
    func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        var dic: [String : SKProduct] = [:]
        for product in response.products { dic[product.productIdentifier] = product }
        products.value = dic
        request = nil
        print("Product: \(response.products.map { "[\($0.productIdentifier, $0.localizedTitle, $0.localizedDescription, $0.localizedPrice)]" })")
    }
    
}

extension Store : SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        Analytics.adRemovePurchased.send()
        deliverProduct(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("restore... \(productIdentifier)")
        Analytics.adRemoveRestored.send()
        deliverProduct(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("failed...")

        if let transactionError = transaction.error as? NSError {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction Error: \(transaction.error?.localizedDescription)")
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }

}

extension Store {

    func deliverProduct(identifier: String) {
        switch identifier {
        case Product.adRemove.identifier:
            if let product = products.value[identifier] {
                purchased.onNext(product)
            }
        default:
            break
        }
    }
    
}

extension Reactive where Base : Store {
    
    func productInfo(_ product: Product) -> Observable<SKProduct> {
        return base.products.asObservable().map { $0[product.identifier] }
            .filter { $0 != nil }
            .map { $0! }
    }
    
    func purchased(_ product: Product) -> Observable<SKProduct> {
        return base.purchased.filter { $0.productIdentifier == product.identifier }
    }
}

extension SKProduct {
    
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        
        return formatter.string(from: price) ?? "Unknown"
    }
}
