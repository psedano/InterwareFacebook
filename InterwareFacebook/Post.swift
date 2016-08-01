//
//  Post.swift
//  InterwareFacebook
//
//  Created by Pablo Sedano on 7/18/16.
//  Copyright © 2016 Pablo Sedano. All rights reserved.
//

import Foundation

class Post {
    private var _postComment : String!
    private var _likes: Int?
    private var _imageUrl: String?
    
    var postComment: String {
        return _postComment
    }
    
    var likes: Int? {
        return _likes
    }
    
    var imageUrl: String? {
        return _imageUrl
    }
    
    init(postComment: String, likes: Int?, imageUrl: String?){
        self._postComment = postComment
        
        if let _ = likes {
           self._likes = likes
        } else {
           self._likes = 0
        }
        
        self._imageUrl = imageUrl
    }
   
}