//
//  Utilities.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 06.01.19.
//  Copyright © 2019 Peter Pohlmann. All rights reserved.
//

import Foundation
import UIKit

class Utilities {
    
    class func defineAlert(title: String, message: String) -> UIAlertController{
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        return alertVC
    }
}
