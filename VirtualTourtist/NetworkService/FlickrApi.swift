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
    
    let apiKey = "81c243af40118e4b01d194b524fc2583"
    //let secrectKey = "dd0cbd8a1939f176"
    //https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=d9602beb0079e839a63a3ff7f9deb85d&tags=test&format=json&nojsoncallback=1
    
    enum Endpoints{
        case baseUrl
        case getPhotosByLocation(latitude:Double, lontitude: Double)
        case downloadPhotoUrl(farm: Int, server: String, id: String, secret: String)
        
        var stringValue: String {
            switch self{
            case .baseUrl:
                return "https://api.flickr.com/services/rest/"
            case .getPhotosByLocation(let latitude, let longitude):
                return Endpoints.baseUrl.stringValue + "?method=flickr.photos.search&api_key=" + shared.apiKey + "&lat=\(latitude)&lon=\(longitude)&per_page=50&format=json&nojsoncallback=1"
            case .downloadPhotoUrl(let farm, let server, let id,  let secret):
                return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
    }
    
    private init(){
    }
    
    func flickrPhotoURL(farmId: String, serverId: String, id: String, secret: String) -> String{
        return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
    }
    
    func loadFlickrPhoto(photo: FlickrPhoto, index: Int, completion: @escaping (UIImage?, Int?, Error?) -> Void ){
        let photoUrl = Endpoints.downloadPhotoUrl(farm: photo.farm, server: photo.server, id: photo.id, secret: photo.secret).url

        let task = URLSession.shared.dataTask(with: photoUrl) { (data, response, error) in
            guard let data = data else{
                print("no photo data")
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
    
    func getPhotosByLocation(latitude: Double, longitude: Double, completion: @escaping (FlickrResponsePhotos?, Error?) -> Void) {
        let endPointURL = Endpoints.getPhotosByLocation(latitude: latitude, lontitude: longitude).url
        let request = URLRequest(url: endPointURL)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else{
                print("request error")
                completion(nil, error)
                return
            }
            
            guard let data = data else{
                print("guard data failed")
                completion(nil, error)
                return
            }
            
            do{
                let result = try JSONDecoder().decode(FlickrResponsePhotos.self, from: data)
                completion(result, nil)
                print("result:############")
            } catch {
                print("decode error")
                completion(nil, error)
            }
        }
        task.resume()
    }
}
