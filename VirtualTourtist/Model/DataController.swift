//
//  DataController.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 27.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import Foundation
import CoreData

class DataController{
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String){
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completionHandler: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (description, error) in
            guard error == nil else{
                print("Persistence Stor Load Error")
                fatalError(error!.localizedDescription)
            }
            print("DataController loaded")
            completionHandler?()
        }
    }
}
