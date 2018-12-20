//
//  MapViewVC.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 20.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import UIKit
import MapKit

class MapViewVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var testButton2: UIButton!
    
    var lastVisibleMapArea: MKMapRect!
    var visibleArea = Dictionary<String, Double>()
    
    @IBAction func testButtonTapped(_ sender: Any) {
        setStoredVisibleArea()
    }
    
    @IBAction func testButton2Tapped(_ sender: Any) {
        persistCurrentVisibleMapArea()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("did load")
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeNotifications()
        print("will disappear")
    }
    
    func setup(){
        addNotifications()
        setStoredVisibleArea()
    }
    
    // MARK: Notifications
    func addNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func removeNotifications(){
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        persistCurrentVisibleMapArea()
    }
    
    // MARK: MAP Functions
    func persistCurrentVisibleMapArea(){
        visibleArea = [
            "x": mapView.visibleMapRect.minX,
            "y": mapView.visibleMapRect.minY,
            "width": mapView.visibleMapRect.width,
            "height": mapView.visibleMapRect.height
        ]
        UserDefaults.standard.set(visibleArea, forKey: "VisibleMapArea")
        print("persist visible area")
        print(visibleArea)
    }
    
    func setStoredVisibleArea(){
        if UserDefaults.standard.object(forKey: "VisibleMapArea") != nil && UserDefaults.standard.bool(forKey: "hasLaunchedBefore"){
            let visibleArea = UserDefaults.standard.dictionary(forKey: "VisibleMapArea") as! Dictionary<String, Double>
            if let x = visibleArea["x"], let y = visibleArea["y"], let width = visibleArea["width"], let height = visibleArea["height"]{
                let storedVisibleArea = MKMapRect(x: x, y:  y, width: width, height: height)
                mapView.visibleMapRect = storedVisibleArea
                print("visible Area")
            }
        }
    }
}
