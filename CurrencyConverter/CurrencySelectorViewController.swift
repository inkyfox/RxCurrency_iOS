//
//  CurrencySelectorViewController.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 24..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class CurrencySelectorViewController: UITableViewController {

    static func createInstance() -> CurrencySelectorViewController {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        return storyBoard.instantiateViewController(withIdentifier: "CurrencySelectorViewController") as! CurrencySelectorViewController
        
    }
    
    static func open(selectedCurrency: Currency, from: UIViewController) -> Observable<Currency> {
        let controller = CurrencySelectorViewController.createInstance()
        controller.selectedCurrency.value = selectedCurrency
        
        let navc = UINavigationController(rootViewController: controller)
        navc.modalPresentationStyle = .overFullScreen
        navc.modalTransitionStyle = .coverVertical

        from.present(navc, animated: true, completion: nil)
        return controller.selectedCurrency.asObservable()
            .skip(1).take(1).takeUntil(controller.dismissed)
    }
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    private var disposeBag: DisposeBag? = DisposeBag()
    private let selectedCurrency = Variable<Currency>(Currency.null)
    private let dismissed = PublishSubject<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        struct Model : CustomStringConvertible {
            let currency: Currency
            let isSelected: Bool
            
            var description: String { return "\(currency.code) : \(isSelected)" }
        }
        
        guard let disposeBag = self.disposeBag else { return }
        
        // bind data source
        do {
            tableView.dataSource = nil
            tableView.delegate = nil
            
            let data: Observable<[Model]> =
                Observable.combineLatest(
                    CurrencyFactory.instance.rx.currencies,
                    selectedCurrency.asObservable()) { (currencies, selected) in
                        currencies.map { Model(currency: $0, isSelected: $0 == selected) }
            }
            
            data.bindTo(tableView.rx.items(cellIdentifier: "CurrencyCell")) { index, model, cell in
                (cell.viewWithTag(1) as? UILabel)?.text = model.currency.flag
                (cell.viewWithTag(2) as? UILabel)?.text = model.currency.code
                (cell.viewWithTag(3) as? UILabel)?.text = model.currency.name
                (cell.viewWithTag(4) as? UILabel)?.isHidden = !model.isSelected
                }
                .addDisposableTo(disposeBag)
        }
        
        // select action
        do {
            let selected = tableView.rx.modelSelected(Model.self).asObservable().publish()
            selected.map { $0.currency }.bindTo(selectedCurrency).addDisposableTo(disposeBag)
            selected.map { _ in return }.bindNext(dismiss).addDisposableTo(disposeBag)
            selected.connect().addDisposableTo(disposeBag)
        }
     
        // cancel action
        do {
            cancelButton.rx.tap.bindNext(dismiss).addDisposableTo(disposeBag)
        }
        

    }

    func dismiss() {
        dismissed.onNext()
        navigationController?.dismiss(animated: true) { [weak self] in self?.disposeBag = nil }
    }

}

