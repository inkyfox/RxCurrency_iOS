//
//  CurrencyView.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 21..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

@IBDesignable class CurrencyView: UIControl {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var flagButton: UIButton!
    @IBOutlet weak var currencyNameButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var slideBar: UISlider!
    
    @IBOutlet weak var button1: NumberButton!
    @IBOutlet weak var button2: NumberButton!
    @IBOutlet weak var button3: NumberButton!
    @IBOutlet weak var button4: NumberButton!
    @IBOutlet weak var button5: NumberButton!
    @IBOutlet weak var button6: NumberButton!
    @IBOutlet weak var button7: NumberButton!
    @IBOutlet weak var button8: NumberButton!
    @IBOutlet weak var button9: NumberButton!
    @IBOutlet weak var button0: NumberButton!
    @IBOutlet weak var button00: NumberButton!
    @IBOutlet weak var button000: NumberButton!
    @IBOutlet weak var buttonDel: NumberButton!
    @IBOutlet weak var buttonReset: NumberButton!

    var logID: String = "notset"
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate let viewModel = CurrencyViewModel()

    var currency: Currency {
        get { return viewModel.currency.currency }
        set { viewModel.currency.currency = newValue }
    }
    
    var number: Double {
        get { return viewModel.number.doubleNumber }
        set { viewModel.number.doubleNumber = newValue }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSubscriptions()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        setupSubscriptions()
    }
    
    private func setupView() {
        Bundle.main.loadNibNamed("CurrencyView", owner: self, options: nil)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.frame = bounds
        addSubview(contentView)
        
    }
    
    private func setupSubscriptions() {
        let nonZeroButtons: [(NumberButton, String)] = [
            (button1, "1"), (button2, "2"), (button3, "3"), (button4, "4"), (button5, "5"),
            (button6, "6"), (button7, "7"), (button8, "8"), (button9, "9")
        ]
        let zeroButtons: [(NumberButton, String)] = [ (button0, "0") ]
        let longNumberButtons: [(NumberButton, String)] = [(button00, "00"), (button000, "000")]
        let numberButtons = nonZeroButtons + zeroButtons + longNumberButtons
        

        // display binding
        do {
            viewModel.currency.rx.flag
                .observeOn(MainScheduler.instance)
                .bindTo(flagButton.rx.title())
                .addDisposableTo(disposeBag)

            viewModel.currency.rx.name
                .map { "\($0 ?? "Unknown") >" }
                .observeOn(MainScheduler.instance)
                .bindTo(currencyNameButton.rx.title())
                .addDisposableTo(disposeBag)
            
            viewModel.currency.rx.code
                .observeOn(MainScheduler.instance)
                .bindTo(currencyLabel.rx.text)
                .addDisposableTo(disposeBag)
            
            viewModel.number.rx.formattedString
                .observeOn(MainScheduler.instance)
                .bindTo(numberLabel.rx.text)
                .addDisposableTo(disposeBag)
            
            viewModel.number.rx.slideValue.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] slide in
                    UIView.animate(withDuration: 0.1) { self?.slideBar.setValue(slide, animated: true) }
                    }
                )
                .addDisposableTo(disposeBag)
            
            let enabled = viewModel.currency.rx.isEnabled.observeOn(MainScheduler.instance).publish()
                
            enabled.bindTo(flagButton.rx.enabled).addDisposableTo(disposeBag)
            enabled.bindTo(currencyNameButton.rx.enabled).addDisposableTo(disposeBag)
            enabled.bindTo(slideBar.rx.enabled).addDisposableTo(disposeBag)
            enabled.bindTo(buttonDel.rx.enabled).addDisposableTo(disposeBag)
            enabled.bindTo(buttonReset.rx.enabled).addDisposableTo(disposeBag)
            
            enabled.connect().addDisposableTo(disposeBag)
        }

        // button states
        do {
            let maxDigitCount = viewModel.number.maxDigitCount
            
            let enabled = viewModel.currency.rx.isEnabled.publish()
            let isNotEmpty = viewModel.number.rx.isNotEmpty.publish()
            let isOne = viewModel.number.rx.digitCount.map { $0 < maxDigitCount }.publish()
            let isTwo = viewModel.number.rx.digitCount.map { $0  + 1 < maxDigitCount }.publish()
            let isThree = viewModel.number.rx.digitCount.map { $0 + 2 < maxDigitCount }.publish()
            
            for (button, _) in nonZeroButtons {
                Observable.combineLatest(enabled, isOne) { $0 && $1 }
                    .observeOn(MainScheduler.instance)
                    .bindTo(button.rx.enabled)
                    .addDisposableTo(disposeBag)
            }
            
            Observable.combineLatest(enabled, isNotEmpty, isOne) { $0 && $1 && $2 }
                .observeOn(MainScheduler.instance)
                .bindTo(button0.rx.enabled)
                .addDisposableTo(disposeBag)

            Observable.combineLatest(enabled, isNotEmpty, isTwo) { $0 && $1 && $2 }
                .observeOn(MainScheduler.instance)
                .bindTo(button00.rx.enabled)
                .addDisposableTo(disposeBag)

            
            Observable.combineLatest(enabled, isNotEmpty, isThree) { $0 && $1 && $2 }
                .observeOn(MainScheduler.instance)
                .bindTo(button000.rx.enabled)
                .addDisposableTo(disposeBag)
            
            isOne.connect().addDisposableTo(disposeBag)
            isTwo.connect().addDisposableTo(disposeBag)
            isThree.connect().addDisposableTo(disposeBag)
            isNotEmpty.connect().addDisposableTo(disposeBag)
            enabled.connect().addDisposableTo(disposeBag)
        }
        
        // number actions
        do {
            Observable.from(numberButtons.map { (button, str) in button.rx.tap.map { str } })
                .merge()
                .bindNext(viewModel.number.append)
                .addDisposableTo(disposeBag)

            buttonDel.rx.tap.bindNext(viewModel.number.deleteLastDigit).addDisposableTo(disposeBag)

            buttonReset.rx.tap.bindNext(viewModel.number.clear).addDisposableTo(disposeBag)

            slideBar.rx.value.bindNext(viewModel.number.setSlide).addDisposableTo(disposeBag)
        }
        
        // currency actions
        do {
            let showCurrency = Observable
                .from([flagButton.rx.tap, currencyNameButton.rx.tap])
                .merge().publish()
            
            showCurrency.map { false }.bindTo(flagButton.rx.enabled).addDisposableTo(disposeBag)
            showCurrency.map { false }.bindTo(currencyNameButton.rx.enabled).addDisposableTo(disposeBag)
            showCurrency.bindNext(showCurrencySelector).addDisposableTo(disposeBag)
            
            showCurrency.connect().addDisposableTo(disposeBag)
        }
        
        // log
        do {
            Observable.from(numberButtons.map { (button, str) in button.rx.tap.map { str } })
                .merge()
                .subscribe(onNext: { [weak self] value in
                    guard let sself = self else { return }
                    Analytics.buttonNumber(viewID: sself.logID,
                                           value: sself.viewModel.number.doubleNumber,
                                           currency: sself.viewModel.currency.currency).send()
                    })
                .addDisposableTo(disposeBag)
            
            slideBar.rx.value.debounce(1, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] value in
                    guard let sself = self else { return }
                    Analytics.slide(viewID: sself.logID,
                                    value: sself.viewModel.number.doubleNumber,
                                    currency: sself.viewModel.currency.currency).send()
                    })
                .addDisposableTo(disposeBag)
        }
    }
    
}

extension CurrencyView {
    
    func showCurrencySelector() {
        guard let vc = window?.rootViewController else { return }
        
        Analytics.currencySelector(viewID: logID).send()

        let viewID = logID
        let before = viewModel.currency.currency
        
        let selected = CurrencySelectorViewController.open(selectedCurrency: before, from: vc).publish()
        
        selected
            .do(onNext: { Analytics.currencyChanged(viewID: viewID, from: before, to: $0).send() })
            .bindTo(viewModel.currency.asObserver()).addDisposableTo(disposeBag)
        selected.subscribe(
            onCompleted: { [weak self] in
                self?.flagButton.isEnabled = true
                self?.currencyNameButton.isEnabled = true
            })
            .addDisposableTo(disposeBag)

        selected.connect().addDisposableTo(disposeBag)
    }
}

extension Reactive where Base: CurrencyView {

    var currency: ControlProperty<Currency> {
        return ControlProperty(values: base.viewModel.currency.asObservable(), valueSink: base.viewModel.currency.asObserver())
    }

    var number: ControlProperty<Double> {
        return ControlProperty(values: base.viewModel.number.asObservable(), valueSink: base.viewModel.number.asObserver())
    }
    
}



