//
//  CurrencyViewModelTests.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 22..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import XCTest
import RxCocoa
import RxSwift
import RxTests

class CurrencyViewModelTests: XCTestCase {
    
    let numberInput: [Recorded<Event<Double>>] = [
        next(0, 0),
        next(150, 100.12),
        
        next(210, 1020.413),
        next(220, 1020.913),
        
        next(310, 31320.413),
        next(320, 31320.913),
        next(330, 31321.0),
        next(340, 31321.13),
        next(350, 31321.7),
        
        next(400, 0.0),
        next(410, 0.01),
        next(420, 0.1001),
        next(430, 0.44499),
        next(431, 0.445),
        next(432, 0.4499),
        next(433, 0.45),
        next(434, 0.4501),
        next(440, 0.4999),
        next(441, 0.50),
        next(442, 0.501),
        next(450, 0.994999),
        next(451, 0.995),
        next(452, 0.999),
        next(453, 1.0),
        next(454, 1.001),
        
        next(500, 123456789.0001),
        next(510, 1234567890.0001),
        
        next(600, 9.4949),
        next(610, 9.4999),
        next(620, 9.99491),
        next(630, 9.99991),
        next(640, 10.0),
        next(650, 10.01),
        ]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFormattedString() {
        let disposeBag = DisposeBag()
        
        let viewModel = CurrencyViewModel()
        viewModel.number.setCurrencySymbol(symbol: "$")
        
        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createHotObservable(numberInput)
        
        xs.bindTo(viewModel.number.asObserver()).addDisposableTo(disposeBag)
        
        let res = scheduler.start { viewModel.number.rx.formattedString.map { $0! } }
        
        let correctMessages: [Recorded<Event<String>>] = [
            next(200, "$100"),
            
            next(210, "$1,020"),
            next(220, "$1,021"),
            
            next(310, "$31,320"),
            next(320, "$31,321"),
            next(330, "$31,321"),
            next(340, "$31,321"),
            next(350, "$31,322"),
            
            next(400, "$0"),
            next(410, "$0.01"),
            next(420, "$0.1"),
            next(430, "$0.44"),
            next(431, "$0.45"),
            next(432, "$0.45"),
            next(433, "$0.45"),
            next(434, "$0.45"),
            next(440, "$0.5"),
            next(441, "$0.5"),
            next(442, "$0.5"),
            next(450, "$0.99"),
            next(451, "$1"),
            next(452, "$1"),
            next(453, "$1"),
            next(454, "$1"),
            
            next(500, "$123,456,789"),
            next(510, "$1,234,567,890"),
            
            next(600, "$9"),
            next(610, "$9"),
            next(620, "$10"),
            next(630, "$10"),
            next(640, "$10"),
            next(650, "$10"),
            ]
        
        XCTAssertEqual(res.events, correctMessages)
    }
    
    func testDigitCount() {
        let disposeBag = DisposeBag()
        
        let viewModel = CurrencyViewModel()

        let scheduler = TestScheduler(initialClock: 0)
        
        let xs = scheduler.createHotObservable(numberInput)
        
        xs.bindTo(viewModel.number.asObserver()).addDisposableTo(disposeBag)
        
        let res = scheduler.start { viewModel.number.rx.digitCount }

        let correctMessages = [
            next(200, 3),
            
            next(210, 4),
            next(220, 4),
            
            next(310, 5),
            next(320, 5),
            next(330, 5),
            next(340, 5),
            next(350, 5),
            
            next(400, 1),
            next(410, 1),
            next(420, 1),
            next(430, 1),
            next(431, 1),
            next(432, 1),
            next(433, 1),
            next(434, 1),
            next(440, 1),
            next(441, 1),
            next(442, 1),
            next(450, 1),
            next(451, 1),
            next(452, 1),
            next(453, 1),
            next(454, 1),
            
            next(500, 9),
            next(510, 10),
            
            next(600, 1),
            next(610, 1),
            next(620, 2),
            next(630, 2),
            next(640, 2),
            next(650, 2),
            ]
        
        XCTAssertEqual(res.events, correctMessages)
    }
    
    
}
