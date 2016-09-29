//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 21..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import GoogleMobileAds

class ViewController: UIViewController {

    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet var removeAdButton: UIBarButtonItem!
    @IBOutlet weak var upperCurrencyView: CurrencyView!
    @IBOutlet weak var lowerCurrencyView: CurrencyView!
    @IBOutlet weak var swapHButton: UIButton!
    @IBOutlet weak var swapVButton: UIButton!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var bannerPositionConstraint: NSLayoutConstraint!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var numberUnlocked = true
    fileprivate var reloadBag = Variable<DisposeBag?>(nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        upperCurrencyView.logID = "upper"
        lowerCurrencyView.logID = "lower"
        
        setupSubscriptions()

        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.delegate = self
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CurrencyNotification.checkReload.post()
    }
    
}

extension ViewController : GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        if Settings.instance.adRemoved ?? false { return }
        bannerPositionConstraint.constant = 0
        UIView.animate(withDuration: 0.4) { [weak self] in self?.view.layoutIfNeeded() }
        navigationItem.leftBarButtonItem = removeAdButton
    }
    
    func prepareAd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let sself = self else { return }
            print("Showing Ad")
            let request = GADRequest()
            #if (arch(i386) || arch(x86_64)) && os(iOS)
                request.testDevices = [kGADSimulatorID]
            #else
                request.testDevices = ["18f57722c93de6cc252c881e6bfc927e"]
            #endif
            sself.bannerView.load(request)
        }
    }
    
    func removeAd() {
        Settings.instance.adRemoved = true
        Settings.instance.synchronize()
        
        navigationItem.leftBarButtonItem = nil
        bannerPositionConstraint.constant = -bannerView.bounds.height
        UIView.animate(withDuration: 0.4,
                       animations: { [weak self] in self?.view.layoutIfNeeded() },
                       completion: { [weak self] _ in self?.view.layoutIfNeeded() })
        UIView.animate(withDuration: 0.4) { [weak self] in self?.bannerView.isHidden = true }
    }
}

extension ViewController {
    func reload() {
        Analytics.load.send()
        
        let reloadDisposeBag = DisposeBag()
        
        reloadBag.value = reloadDisposeBag

        let before = Date().timeIntervalSince1970
        
        let reload = API.default.request(.latest)
            .observeOn(ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .background))
            .flatMap { CurrencyFactory.instance.rx.parse(json: $0) }
            .observeOn(MainScheduler.instance).publish()
        
        reload
            .subscribe(
                onError: { [weak self] error in
                    self?.reloadBag.value = nil
                    Analytics.loadFailed(elapsed: Date().timeIntervalSince1970 - before).send()
                },
                onCompleted: { [weak self] error in
                    self?.reloadBag.value = nil
                    Analytics.loadSuccess(elapsed: Date().timeIntervalSince1970 - before).send()
                }
            )
            .addDisposableTo(reloadDisposeBag)
        
        reload.connect().addDisposableTo(reloadDisposeBag)
    }
}

extension ViewController {
    fileprivate func setupSubscriptions() {
        // ad
        do {
            navigationItem.leftBarButtonItem = nil
            if let removed = Settings.instance.adRemoved, removed {
            } else {
                Store.instance.rx.productInfo(Product.adRemove)
                    .map { _ in return }
                    .do(onError: { error in Analytics.productInfoLoadFailed(error: error.localizedDescription).send() })
                    .bindNext(prepareAd)
                    .addDisposableTo(disposeBag)

                Store.instance.rx.purchased(Product.adRemove)
                    .map { _ in return }
                    .bindNext(removeAd)
                    .addDisposableTo(disposeBag)
                        
                removeAdButton.rx.tap
                    .do(onNext: { _ in Analytics.buttonStore.send() })
                    .subscribe(onNext: { [weak self] in
                        guard let sself = self else { return }
                        guard let product = Store.instance.product(Product.adRemove) else { return }
                        sself.rx.actionSheet(sender: sself.removeAdButton,
                                             items: ["\(product.localizedTitle): \(product.localizedPrice)",
                                                NSLocalizedString("Restore Purchase", comment: "")
                            ])
                            .subscribe(onNext: { [weak product] (index, item) in
                                guard let sproduct = product else { return }
                                switch index {
                                case 0:
                                    Analytics.buttonPurchase.send()
                                    Store.instance.purchase(product: sproduct)
                                case 1:
                                    Analytics.buttonRestore.send()
                                    Store.instance.restore()
                                default: break
                                }
                                })
                            .addDisposableTo(sself.disposeBag)
                        })
                    .addDisposableTo(disposeBag)
                
                Store.instance.loadProducts()
            }
        }
        
        // reload
        do {
            CurrencyNotification.checkReload.rx.post
                .map { _ in return }
                .filter { _ in
                    guard let updated = CurrencyFactory.instance.updatedTime else { return true }
                    return Date().timeIntervalSince1970 - updated > API.default.updateInterval
                }
                .debounce(0.1, scheduler: MainScheduler.instance)
                .do(onNext: {
                    guard let updated = CurrencyFactory.instance.updatedTime else { return }
                    Analytics.periodicReload(elapsed: Date().timeIntervalSince1970 - updated)
                        .send()
                })
                .bindNext(reload)
                .addDisposableTo(disposeBag)
            
            reloadButton.rx.tap
                .debounce(0.3, scheduler: MainScheduler.instance)
                .do(onNext: { Analytics.buttonReload.send() })
                .bindNext(reload)
                .addDisposableTo(disposeBag)
            
            Observable.from([rx.isLoading.map { !$0 }, reloadButton.rx.tap.map { false } ])
                .merge()
                .bindTo(reloadButton.rx.enabled)
                .addDisposableTo(disposeBag)
            
            reloadBag.asObservable()
                .map { $0 != nil }
                .bindTo(UIApplication.shared.rx.networkActivityIndicatorVisible)
                .addDisposableTo(disposeBag)
        }
        
        // rate date
        do {
            Observable.combineLatest(
                CurrencyFactory.instance.rx.rateDateString, rx.isLoading) { (string, isLoading) in
                    return isLoading ?
                        NSLocalizedString("Refreshing...", comment: "") :
                        String.localizedStringWithFormat(NSLocalizedString("Rates at %@", comment: ""), string)
                }
                .observeOn(MainScheduler.instance)
                .bindTo(rx.title)
                .addDisposableTo(disposeBag)
        }
        
        // API loaded
        do {
            let initial = CurrencyFactory.instance.rx.currencies.take(1).observeOn(MainScheduler.instance).publish()
            
            initial
                .map { [weak self] _ in self?.defaultUpperCurrency ?? Currency.null }
                .bindTo(upperCurrencyView.rx.currency)
                .addDisposableTo(disposeBag)
            
            initial
                .map { [weak self] _ in self?.defaultLowerCurrency ?? Currency.null }
                .bindTo(lowerCurrencyView.rx.currency)
                .addDisposableTo(disposeBag)
            
            initial.map { _ in return }.bindNext(lockNumber).addDisposableTo(disposeBag)

            initial
                .map { _ in Settings.instance.lowerNumber ?? 0 }
                .bindTo(lowerCurrencyView.rx.number)
                .addDisposableTo(disposeBag)

            initial.connect().addDisposableTo(disposeBag)
        }
        
        // API loaded
        do {
            let update = CurrencyFactory.instance.rx.currencies.skip(1).observeOn(MainScheduler.instance).publish()

            update
                .subscribe(onNext: { [weak self] _ in
                    guard let sself = self else { return }
                    let currency = sself.upperCurrencyView.currency
                    sself.upperCurrencyView.currency =
                        CurrencyFactory.instance.contains(currencyCode: currency.code) ?
                            currency : sself.defaultUpperCurrency
                })
                .addDisposableTo(disposeBag)
            
            update
                .subscribe(onNext: { [weak self] _ in
                    guard let sself = self else { return }
                    if CurrencyFactory.instance.contains(currencyCode: sself.lowerCurrencyView.currency.code) { return }
                    sself.lowerCurrencyView.currency = sself.defaultLowerCurrency
                })
                .addDisposableTo(disposeBag)

            update.connect().addDisposableTo(disposeBag)

        }
        
        // convert action
        do {
            let toLower = Observable.combineLatest(
                upperCurrencyView.rx.number,
                lowerCurrencyView.rx.currency
            ) { $0 }
                .filter { [weak self] _ in self?.checkLock() ?? false }
                .map { [weak upperCurrencyView] in
                    ($0, upperCurrencyView?.currency ?? Currency.null, $1)
                }
                .map(CurrencyFactory.instance.convert)
                .publish()
            
            toLower.map { _ in return }.bindNext(lockNumber).addDisposableTo(disposeBag)
            toLower.bindTo(lowerCurrencyView.rx.number).addDisposableTo(disposeBag)
            
            toLower.connect().addDisposableTo(disposeBag)
            
            
            let toUpper = Observable.combineLatest(
                lowerCurrencyView.rx.number,
                upperCurrencyView.rx.currency
            ) { $0 }
                .filter { [weak self] _ in self?.checkLock() ?? false}
                .map { [weak lowerCurrencyView] in
                    ($0, lowerCurrencyView?.currency ?? Currency.null, $1)
                }
                .map(CurrencyFactory.instance.convert)
                .publish()
            
            toUpper.map { _ in return }.bindNext(lockNumber).addDisposableTo(disposeBag)
            toUpper.bindTo(upperCurrencyView.rx.number).addDisposableTo(disposeBag)
            
            toUpper.connect().addDisposableTo(disposeBag)
        }
        
        // swap
        do {
            Observable.from([swapHButton.rx.tap, swapVButton.rx.tap]).merge()
                .do(onNext: { Analytics.buttonSwap.send() })
                .bindNext(swap).addDisposableTo(disposeBag)
        }
        
        // status
        do {
            upperCurrencyView.rx.currency.bindTo(Settings.instance.rx.upperCurrency).addDisposableTo(disposeBag)
            lowerCurrencyView.rx.currency.bindTo(Settings.instance.rx.lowerCurrency).addDisposableTo(disposeBag)
            lowerCurrencyView.rx.number.bindTo(Settings.instance.rx.lowerNumber).addDisposableTo(disposeBag)
        }
    }
}

extension ViewController {
    fileprivate var defaultUpperCurrency: Currency {
        return Settings.instance.upperCurrency ??
            CurrencyFactory.instance.currency(ofLocale: Locale.current) ??
            CurrencyFactory.instance.currency(ofCode: "USD") ??
            CurrencyFactory.instance.firstCurrency ??
            Currency.null
    }

    fileprivate var defaultLowerCurrency: Currency {
        return Settings.instance.lowerCurrency ??
            CurrencyFactory.instance.currency(ofCode: "USD") ??
            CurrencyFactory.instance.firstCurrency ??
            Currency.null
    }

    fileprivate func lockNumber() {
        numberUnlocked = false
    }
    
    fileprivate func checkLock() -> Bool {
        if numberUnlocked { return true }
        numberUnlocked = true
        return false
    }
    
    fileprivate func swap() {
        let upperCurrency = upperCurrencyView.currency
        let upperNumber = upperCurrencyView.number
        
        lockNumber()
        upperCurrencyView.currency = lowerCurrencyView.currency
        lockNumber()
        upperCurrencyView.number = lowerCurrencyView.number
        lockNumber()
        lowerCurrencyView.currency = upperCurrency
        lockNumber()
        lowerCurrencyView.number = upperNumber
    }
    
}

extension Reactive where Base : ViewController {
    
    var isLoading: Observable<Bool> {
        return base.reloadBag.asObservable().map { $0 != nil }
    }
    
    func actionSheet(sender: AnyObject, items: [String]) -> Observable<(index: Int, value: String)> {
        return Observable.create({ [weak base] (observer) -> Disposable in
            guard let sbase = base else { return Disposables.create() }
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            if let presenter = alert.popoverPresentationController {
                if let view = sender as? UIView {
                    presenter.sourceView = view
                } else if let barButton = sender as? UIBarButtonItem {
                    presenter.barButtonItem = barButton
                    presenter.sourceView = sbase.view
                } else {
                    return Disposables.create()
                }
            }
            
            items.enumerated().forEach { (index, item) in
                let action = UIAlertAction(title: item, style: .default, handler: { (action) in
                    observer.onNext((index: index, value: item))
                    observer.onCompleted()
                })
                alert.addAction(action)
            }
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                          style: .cancel,
                                          handler: { _ in observer.onCompleted() }))
            
            sbase.present(alert, animated: true, completion: nil)
            
            return Disposables.create {
                alert.dismiss(animated: false, completion: nil)
            }
            })
    }
}

