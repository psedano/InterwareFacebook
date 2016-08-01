//
//  PostTableViewCell.swift
//  InterwareFacebook
//
//  Created by Pablo Sedano on 7/15/16.
//  Copyright © 2016 Pablo Sedano. All rights reserved.
//

import UIKit
import Alamofire

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var imgPost: UIImageView!
    @IBOutlet weak var imgLikes: UIImageView!
    @IBOutlet weak var stackViewLikes: UIStackView!
    
    var request: Request?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        layer.shadowColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.5).CGColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.shadowOffset = CGSizeMake(0.0, 2.0)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(post: Post, image: UIImage?){
        self.stackViewLikes.hidden = true
        self.imgPost.hidden = false
        self.imgLikes.hidden = true
        
        txtDescription.text = post.postComment
        lblUsername.text = NSUserDefaults.standardUserDefaults().objectForKey("username") as? String
        lblLikes.text = "\(post.likes)"
        let imageUrl = post.imageUrl
        
        if imageUrl != nil {
            if image != nil {
                self.imgPost.image = image
            } else {
                request = Alamofire.request(.GET, imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, error in
                    
                    if error == nil {
                        let img = UIImage(data: data!)!
                        self.imgPost.image = img
                        //CACHE
                        MainViewController.imgCache.setObject(img, forKey: imageUrl!)
                    }
                    
                })
            }
        } else {
            self.imgPost.hidden = true
        }
        
    }

}
