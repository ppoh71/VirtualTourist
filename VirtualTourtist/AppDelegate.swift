//
//  AppDelegate.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 20.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let dataController = DataController(modelName: "VirtualTourist")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        checkIfFirstLaunch()
        
        //DataController Injection
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let mapVC = navigationController.topViewController as! MapViewVC
        mapVC.dataController = dataController
        return true
    }
    
    func checkIfFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            print("first launch")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}

