//
//  MainViewController.swift
//  InterwareFacebook
//
//  Created by Pablo Sedano on 7/15/16.
//  Copyright © 2016 Pablo Sedano. All rights reserved.
//

import UIKit
import Parse
import Alamofire
import Google
import Crashlytics

class MainViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var imagePicker: UIImagePickerController!
    static var imgCache = NSCache()
    var arrPost = [Post]()
    var imageSelected = false

    @IBOutlet weak var tblPosts: UITableView!
    @IBOutlet weak var imgSelection: UIImageView!
    @IBOutlet weak var txtComment: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        txtComment.delegate = self
        activityIndicator.layer.zPosition = 1
        
        let query = PFQuery(className: "posts").addDescendingOrder("_created_at")
        
        query.findObjectsInBackgroundWithBlock { pfObject, error in
            
            if error != nil {
                print("THERE'S AN ERROR")
                self.showErrorAlert("Error", msg: "There's an error displaying the data, please try again later")
                
            } else {
                
                for posts in pfObject! {
                    let mLabPost = Post(postComment: posts["description"] as! String, likes: posts["likes"] as? Int, imageUrl: posts["imageUrl"] as? String)
                    self.arrPost.append(mLabPost)
                }
            
                self.tblPosts.reloadData()
            }
            
            
        }
        
    }
    
    @IBAction func crashButtonTapped(sender: AnyObject) {
        Crashlytics.sharedInstance().crash()
    }
    
    override func viewWillAppear(animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Main View Controller")
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrPost.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") as? PostTableViewCell{
            
            let singlePost = arrPost[indexPath.row]
            
            var img: UIImage?
            
            if let url = singlePost.imageUrl {
                img = MainViewController.imgCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(singlePost, image: img)
            
            return cell
        }
        
        return PostTableViewCell()
        
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imgSelection.image = image
        imageSelected = true
    }
    
    @IBAction func gestureRecognizer(sender: UITapGestureRecognizer) {
         imagePicker.sourceType = .Camera
         presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func showErrorAlert(title: String, msg: String){
        let alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style:.Default, handler: nil)
        
        alertCtrl.addAction(alertAction)
        presentViewController(alertCtrl, animated: true, completion: nil)
    }
    
    @IBAction func makePost(sender: UIButton!){
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("IBAction", action: "button_press", label: "makePost", value: nil).build() as [NSObject : AnyObject])
        activityIndicator.startAnimating()
        txtComment.resignFirstResponder()
        if txtComment.text != "" {
            
            if let imgThumb = imgSelection.image where imageSelected == true {
                let urlStr = IMAGE_SHACK_URL
                let url = NSURL(string: urlStr)!
                let imgData = UIImageJPEGRepresentation(imgThumb, 0.2)!
                
                //Multipart request
                let keyData = IMAGE_SHACK_KEY.dataUsingEncoding(NSUTF8StringEncoding)
                let keyJSON = "json".dataUsingEncoding(NSUTF8StringEncoding)
                
                Alamofire.upload(.POST, url, multipartFormData: { multipartFormData in
                    
                    multipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpeg")
                    multipartFormData.appendBodyPart(data: keyData!, name: "key")
                    multipartFormData.appendBodyPart(data: keyJSON!, name: "format")
                    
                    
                }) { encodingResult in
                    
                    switch encodingResult {
                        
                    case .Success(let upload, _, _):
                        upload.responseJSON(completionHandler: { response in
                            
                            if let info = response.result.value as? Dictionary<String, AnyObject>{
                                if let links = info["links"] as? Dictionary<String, AnyObject> {
                                    if let imgLink = links["image_link"] as? String {
                                        self.postTomLab(imgLink)
                                    }
                                }
                            }
                        })
                        
                        
                    case .Failure(let error):
                        print(error)
                        self.activityIndicator.stopAnimating()
                    }
                    
                }
            } else {
                postTomLab(nil)
            }
        } else {
            activityIndicator.stopAnimating()
            showErrorAlert("Mensaje", msg: "Favor de incluir un comentario en su publicación")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let post = arrPost[indexPath.row]
        
        if post.imageUrl == nil {
            return 115
        } else {
            return 346
        }
        
    }
    
    func postTomLab(imageLink: String?) {
        let post = Post(postComment: txtComment.text!, likes: 0, imageUrl: nil)
        let object = PFObject(className: "posts")
        object.setObject(post.likes!, forKey: "likes")
        
        object.setObject(post.postComment, forKey: "description")
        
        if let postImage = imageLink {
            object.setObject(postImage, forKey: "imageUrl")
        }
        
        
        object.saveInBackgroundWithBlock({ success, error in
            
            if success{
                
                let query = PFQuery(className: "posts").addDescendingOrder("_created_at")
                
                query.findObjectsInBackgroundWithBlock { pfObject, error in
                    
                    if error != nil {
                        print("THERE'S AN ERROR")
                        self.showErrorAlert("Error", msg: "There's an error displaying the data, please try again later")
                        self.activityIndicator.stopAnimating()
                        
                    } else {
                        
                        self.arrPost = [Post]()
                        
                        for posts in pfObject! {
                            let mLabPost = Post(postComment: posts["description"] as! String, likes: posts["likes"] as? Int, imageUrl: posts["imageUrl"] as? String)
                            self.arrPost.append(mLabPost)
                        }
                        
                        self.txtComment.text = ""
                        self.imgSelection.image = UIImage(named: "Camera-icon")
                        self.imageSelected = false
                        self.tblPosts.reloadData()
                        self.activityIndicator.stopAnimating()
                        
                    }
                    
                    
                }
                
            }
            
        })

    }
    
}
