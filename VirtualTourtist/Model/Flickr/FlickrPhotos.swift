//
//  Photos.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 28.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import Foundation

struct FlickrPhotos: Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    //let total: Int
    let photo: [FlickrPhoto] 
}
