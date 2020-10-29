//
//  GFAvatarImageView.swift
//  GHFollowers
//
//  Created by billy pak on 10/8/20.
//  Copyright © 2020 Sean Allen. All rights reserved.
//

import UIKit

class GFAvatarImageView: UIImageView {
    
    let cache           = NetworkManager.shared.cache
    //force unwrap because image file is local (USE OPTIONAL if online)
    let placeholderImage = UIImage(named: "avatar-placeholder")!

    override init(frame: CGRect){
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure()
    {
        layer.cornerRadius  = 10
        clipsToBounds       = true     //need this code to make image have cornerRadius
        image               = placeholderImage
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    //going to do network call ehre
    func downloadImage(from urlString: String){
        
        let cacheKey = NSString(string: urlString)
        if let image = cache.object(forKey: cacheKey) {
            self.image = image
            return
        }
        
        //network call not handling errors because (placeholder image as the error)
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with:url) {[weak self] data, response, error in
            guard let self = self else { return }
            
            if error != nil { return } //intentionally not handling error
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return }
            guard let data = data else { return } // making sure we have data
            
            guard let image = UIImage(data: data) else { return }
            
            //setting image to the cache.
            self.cache.setObject(image, forKey: cacheKey)
            
            //we have to set the avatar image (we are on the background thread so now we have to setup on the main thread
            //anytime we setup a UI change on main thread
            DispatchQueue.main.async {
                self.image = image
            }
        }
        task.resume() // kicks off our network call
        
        
    }

}
