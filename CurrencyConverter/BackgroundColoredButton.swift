//
//  BackgroundColoredButton.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 21..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import UIKit

@IBDesignable class BackgroundColoredButton: UIButton {

    @IBInspectable var bgColorHighlighted : UIColor? = nil { didSet { if awaken { stateDidChange() } } }
    @IBInspectable var bgColorDisabled : UIColor? = nil { didSet { if awaken { stateDidChange() } } }

    private var bgColorNormal : UIColor? = nil

    private var awaken = false

    override var isHighlighted : Bool {
        didSet {
            if let color = bgColorHighlighted,
                color != UIColor.clear && isHighlighted != oldValue {
                if isHighlighted {
                    stateDidChange()
                } else {
                    UIView.animate(withDuration: 0.4,
                                   delay: 0,
                                   options: .allowUserInteraction,
                                   animations: { [weak self] in self?.stateDidChange() }
                    )
                }
            }
        }
    }
    
    override var isEnabled : Bool {
        didSet {
            if let color = bgColorDisabled,
                color != UIColor.clear && isEnabled != oldValue {
                stateDidChange()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        awaken = true
        bgColorNormal = backgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        stateDidChange()
    }
    
    private func stateDidChange() {
        if !isEnabled {
            if let color = bgColorDisabled, color != UIColor.clear {
                backgroundColor = color
            }
        } else if isHighlighted {
            if let color = bgColorHighlighted, color != UIColor.clear {
                backgroundColor = color
            }
        } else {
            if let color = bgColorNormal {
                backgroundColor = color
            } else {
                backgroundColor = nil
            }
        }
    }

}
