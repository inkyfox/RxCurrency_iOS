//
//  NumberButton.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 21..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import UIKit

class NumberButton: BackgroundColoredButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        bgColorHighlighted = UIColor(red: 0, green: 0.5, blue: 0, alpha: 0.7)
        bgColorDisabled = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        
        setTitleColor(UIColor.black, for: .normal)
        setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .highlighted)
        setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .disabled)
    }
}
