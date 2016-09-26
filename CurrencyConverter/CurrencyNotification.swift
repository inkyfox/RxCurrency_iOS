//
//  CurrencyNotification.swift
//  CurrencyConverter
//
//  Created by Yongha Yoo (inkyfox) on 2016. 9. 26..
//  Copyright © 2016년 Gen X Hippies Company. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

enum CurrencyNotification : String {
    case checkReload
    
    var name: Notification.Name {
        return Notification.Name(rawValue)
    }
}



extension CurrencyNotification {
    
    func post(object: AnyObject? = nil, userInfo: [NSObject : AnyObject]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
    struct Reactive {
        fileprivate let base: CurrencyNotification
        
        init(_ base: CurrencyNotification) {
            self.base = base
        }
    }
    
    var rx: Reactive { return Reactive(self) }

}

extension CurrencyNotification.Reactive {
    
    var post: Observable<Notification> {
        return NotificationCenter.default.rx.notification(base.name)
    }
    
}
