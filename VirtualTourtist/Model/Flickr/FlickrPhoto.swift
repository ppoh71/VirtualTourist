//
//  Photo.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 28.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import Foundation

struct FlickrPhoto: Codable{
    let id: String
    let secret: String
    let server: String
    let farm: Int
    let title: String

    enum CodingKeys: String, CodingKey{
        case id
        case secret
        case server
        case farm
        case title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "default"
        self.secret = try container.decodeIfPresent(String.self, forKey: .secret) ?? "default"
        self.server = try container.decodeIfPresent(String.self, forKey: .server) ?? "default"
        self.farm = try container.decodeIfPresent(Int.self, forKey: .farm) ?? 5
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "default"
    }
}
