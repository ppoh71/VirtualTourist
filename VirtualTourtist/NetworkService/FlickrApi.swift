//
//  FlickrApi.swift
//  VirtualTourtist
//
//  Created by Peter Pohlmann on 28.12.18.
//  Copyright © 2018 Peter Pohlmann. All rights reserved.
//

import Foundation
import UIKit

class FlickrApi{
    
    static let shared = FlickrApi()
    
    private init(){}
    
    let apiKey = "81c243af40118e4b01d194b524fc2583"
    //let secrectKey = "dd0cbd8a1939f176"
    
    enum Endpoints{
        case baseUrl
        case getPhotosByLocation(latitude:Double, lontitude: Double, resultPage: Int)
        case downloadPhotoUrl(farm: Int, server: String, id: String, secret: String)
        
        var stringValue: String {
            switch self{
            case .baseUrl:
                return "https://api.flickr.com/services/rest/"
            case .getPhotosByLocation(let latitude, let longitude, let resultPage):
                return Endpoints.baseUrl.stringValue + "?method=flickr.photos.search&api_key=" + shared.apiKey + "&lat=\(latitude)&lon=\(longitude)&per_page=27&page=\(resultPage)&format=json&nojsoncallback=1"
            case .downloadPhotoUrl(let farm, let server, let id,  let secret):
                return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
    }
    
    func loadFlickrPhoto(photo: FlickrPhoto, index: Int, completion: @escaping (UIImage?, Int?, Error?) -> Void ){
        let photoUrl = Endpoints.downloadPhotoUrl(farm: photo.farm, server: photo.server, id: photo.id, secret: photo.secret).url
        
        let task = URLSession.shared.dataTask(with: photoUrl) { (data, response, error) in
            guard let data = data else{
                completion(nil, index, nil)
                return
            }
            
            if let image = UIImage(data: data){
                DispatchQueue.main.async {
                    completion(image, index, nil)
                }
            }
        }
        task.resume()
    }
    
    func getPhotosByLocation(latitude: Double, longitude: Double, resultPage: Int, completion: @escaping (FlickrResponsePhotos?, Error?) -> Void) {
        let endPointURL = Endpoints.getPhotosByLocation(latitude: latitude, lontitude: longitude, resultPage: resultPage).url
        let request = URLRequest(url: endPointURL)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else{
                completion(nil, error)
                return
            }
            
            guard let data = data else{
                completion(nil, error)
                return
            }
            
            do{
                let result = try JSONDecoder().decode(FlickrResponsePhotos.self, from: data)
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
