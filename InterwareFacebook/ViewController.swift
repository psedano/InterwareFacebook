//
//  ViewController.swift
//  InterwareFacebook
//
//  Created by Pablo Sedano on 7/14/16.
//  Copyright © 2016 Pablo Sedano. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Parse
import Google
import LocalAuthentication
import CryptoSwift

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var emailLoginButton: UIButton!
    @IBOutlet weak var lblOR: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var imgConstraint: NSLayoutConstraint!
    
    let authenticationContext = LAContext()
    var userUID = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        txtEmail.delegate = self
        txtPassword.delegate = self
        
        setupAnimations()
        beginAnimations()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        askForTouchID()
    }
    
    
    @IBAction func btnPressed() {
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: Google Analytics
    override func viewWillAppear(animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "View Controller")
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
        
    }

    // MARK: Facebook Login
    @IBAction func fbBtnLogin(sender: AnyObject) {
        //Send the event to Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("IBAction", action: "button_press", label: "fbBtnLogin", value: nil).build() as [NSObject : AnyObject])
        
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"], fromViewController: self) { facebookResult, facebookError in
            
            if facebookError != nil {
                self.showErrorAlert("Error", message: "Error login to Facebook, please try again")
            } else {
                //let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                
                if facebookResult.isCancelled == false {
                    FBSDKGraphRequest.init(graphPath: "me", parameters: nil).startWithCompletionHandler({ connection, result, error in
                        
                        if error == nil {
                            let newUser = PFObject(className: "users")
                            newUser["username"] = result.objectForKey("name")
                            newUser["provider"] = "facebook"
                            
                            newUser.saveInBackgroundWithBlock({ success, error in
                                if success {
                                    self.userUID = newUser.objectId!
                                    NSUserDefaults.standardUserDefaults().setObject(newUser.objectId!, forKey: "uid")
                                    NSUserDefaults.standardUserDefaults().setObject(newUser["username"], forKey: "username")
                                    //Proceed to the next screen
                                    self.performSegueWithIdentifier(SEGUE_MAIN_SCREEN, sender: nil)
                                } else {
                                    self.showErrorAlert("Error", message: "\(error?.code)")
                                    self.activityIndicator.stopAnimating()
                                }
                                
                            })
                            
                            //Proceed to the next screen
                            self.performSegueWithIdentifier(SEGUE_MAIN_SCREEN, sender: nil)
                        }
                    })

                } else {
                    self.activityIndicator.stopAnimating()
                }
            }
            
        }
    }
    
    // MARK: Email Login
    @IBAction func btnEmailLogin(sender: AnyObject){
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("IBAction", action: "button_press", label: "btnEmailLogin", value: nil).build() as [NSObject : AnyObject])
        
        activityIndicator.startAnimating()
        if txtEmail.text != "" && txtPassword.text != "" {
            
            if isValidEmail(txtEmail.text!) {
                let query = PFQuery(className: "users")
                query.whereKey("username", equalTo: txtEmail.text!)
                
                query.findObjectsInBackgroundWithBlock { pfObject, error in
                    
                    if error != nil {
                        self.activityIndicator.stopAnimating()
                        print("THERE'S AN ERROR")
                        self.showErrorAlert("Error", message: "There's an error displaying the data, please try again later")
                    } else {
                        
                        print(pfObject)
                        
                        if pfObject!.count > 0 {
                            
                            //Encrypt the password
                            let pwdBytes = self.txtPassword.text!.utf8.map({$0})
                            let encryptedPassword = pwdBytes.md5().toHexString()
                            
                            if pfObject![0]["password"] as! String == encryptedPassword {
                                NSUserDefaults.standardUserDefaults().setObject(pfObject![0].objectId!, forKey: "uid")
                                NSUserDefaults.standardUserDefaults().setObject(pfObject![0]["username"], forKey: "username")
                                self.performSegueWithIdentifier(SEGUE_MAIN_SCREEN, sender: nil)
                            } else {
                                self.activityIndicator.stopAnimating()
                                self.showErrorAlert("Error", message: "La contraseña no es correcta")
                            }
                        } else {
                            let newUser = PFObject(className: "users")
                            newUser["username"] = self.txtEmail.text!
                            
                            //Encrypt the password
                            let pwdBytes = self.txtPassword.text!.utf8.map({$0})
                            let encryptedPassword = pwdBytes.md5()
                            
                            newUser["password"] = encryptedPassword.toHexString()
                            newUser["provider"] = "Email"
                            
                            newUser.saveInBackgroundWithBlock({ success, error in
                                if success {
                                    NSUserDefaults.standardUserDefaults().setObject(newUser.objectId!, forKey: "uid")
                                    NSUserDefaults.standardUserDefaults().setObject(newUser["username"], forKey: "username")
                                    //Proceed to the next screen
                                    self.activityIndicator.stopAnimating()
                                    self.performSegueWithIdentifier(SEGUE_MAIN_SCREEN, sender: nil)
                                } else {
                                    self.activityIndicator.stopAnimating()
                                    self.showErrorAlert("Error", message: "\(error?.code)")
                                }
                            })
                        }
                        
                    }
                    
                    
                }
            } else {
                activityIndicator.stopAnimating()
                showErrorAlert("Error", message: "El formato de correo no es correcto")
            }

        } else {
            activityIndicator.stopAnimating()
            showErrorAlert("Error", message: "Favor de proporcionar un usuario y contraseña")
        }
    }
    
    func showErrorAlert(title: String, message: String){
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("Function", action: "showErrorAlert", label: message, value: nil).build() as [NSObject : AnyObject])
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: TouchID Authentication
    func askForTouchID() {
        if NSUserDefaults.standardUserDefaults().objectForKey("uid") != nil {
            
            if authenticationContext.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
                
                authenticationContext.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Por favor proporciona tu huella", reply: { (success: Bool, error: NSError?) in
                    
                    if success {
                        self.performSegueWithIdentifier(SEGUE_MAIN_SCREEN, sender: nil)
                    } else {
                        self.showErrorAlert("Error de autenticacion", message: "Tu huella no corresponde, intenta de nuevo")
                    }
                    
                })
            } else {
                self.performSegueWithIdentifier(SEGUE_MAIN_SCREEN, sender: nil)
            }
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    // MARK: Animations
    func setupAnimations() {
        imgLogo.alpha = 0.0
        txtEmail.alpha = 0.0
        txtPassword.alpha = 0.0
        fbLoginButton.alpha = 0.0
        emailLoginButton.alpha = 0.0
        lblOR.alpha = 0.0
    }
    
    func beginAnimations() {
        UIView.animateWithDuration(2, animations: {
            
            self.imgLogo.alpha = 1.0
            
        }) { success in
            
            self.imgConstraint.constant = -(self.view.bounds.height / 4) - self.txtEmail.frame.height
            
            UIView.animateWithDuration(0.5, animations: {
                self.view.layoutIfNeeded()
            }) { success in
                UIView.animateWithDuration(1, animations: {
                    self.txtEmail.alpha = 1.0
                    self.txtPassword.alpha = 1.0
                    self.fbLoginButton.alpha = 1.0
                    self.emailLoginButton.alpha = 1.0
                    self.lblOR.alpha = 1.0
                })
            }
        }
    }

    
}

