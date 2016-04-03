//
//  Profile.swift
//  alphaFourTP
//
//  Created by Fito Toledano Carmona on 11/10/15.
//  Copyright © 2015 Fito Toledano Carmona. All rights reserved.
//

import Foundation
import UIKit
import Parse
import Bolts
import MapKit
import CoreLocation
import ParseTwitterUtils
import Social
import Accounts

class Profile: UIViewController, UINavigationControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate,  UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // Variables to store current User info.
    var imageFiles = [PFFile]()
    var postMessages = [String]()
    
    // This is a refresh control, to refresh the list.
    var refresher: UIRefreshControl!
    
    // User Stats Labels
    @IBOutlet weak var userEventsLabel: UILabel!
    @IBOutlet weak var userPeepsLabel: UILabel!
    @IBOutlet weak var userPostsLabel: UILabel!
    
    // Queries for User Stats
    var eventQuery = PFQuery(className: "Events")
    var peepsQuery = PFQuery(className: "Peeps")
    var postsQuery = PFQuery(className: "Post")
    
    // Variables to save and retrieve the user Image.
    var userPhoto = PFObject(className:"UserPhoto")
    let photoQuery = PFQuery(className: "UserPhoto")
    var newImage = UIImage()


    // Interface Outlets.
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userInfoView: UIView!
    
    func getStats(){
        eventQuery.whereKey("sender", equalTo: PFUser.currentUser()!.username!)
        eventQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                self.userEventsLabel.text = String(objects!.count)
            }
        }
        
        peepsQuery.whereKey("follower", equalTo: PFUser.currentUser()!.objectId!)
        peepsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                self.userPeepsLabel.text = String(objects!.count)
            }
        }
        
        postsQuery.whereKey("userId", equalTo: PFUser.currentUser()!.objectId!)
        postsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                self.userPostsLabel.text = String(objects!.count)
            }
        }
    
    }
    
    
    override func viewDidLoad() {
        userAvatar.layer.cornerRadius = userAvatar.frame.size.width / 2
        userAvatar.clipsToBounds = true
        
        // Sets the username label to the current User username.
        userName.text? = (PFUser.currentUser()!.username!).uppercaseString
        
        // Calls function to load the user avatar.
        loadImages()
        
        // Gets user's stats
        getStats()
    }
    

    override func viewDidAppear(animated: Bool) {
        // Add any functions when this view appears.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("feedCell", forIndexPath: indexPath) as? ProfilePostCell
        
        imageFiles[indexPath.row].getDataInBackgroundWithBlock { (data, error) -> Void in
            if let downloadedImage = UIImage(data: data!) {
                cell?.displayedPicture.image = downloadedImage
                
            }
        }
        
        cell?.displayedLabel!.text = postMessages[indexPath.row]
        
        
        
        return cell!
        
    }

    // Loads the user Avatar.
    func loadImages(){
        // We query objects with the current username in the backend. (Should be only 1, obviously)
        photoQuery.whereKey("username", equalTo: (PFUser.currentUser()?.username!)!)
        photoQuery.findObjectsInBackgroundWithBlock{
            (objects,error) -> Void in
            if error == nil {
                // If there's an image, stored as imageFile in the user object, get data.
                if let imageFile = PFUser.currentUser()!.objectForKey("imageFile") as? PFFile {
                    imageFile.getDataInBackgroundWithBlock{
                        (data, error) -> Void in
                        if error == nil {
                            if let imageData = data {
                                // Sets the image outlet to the data retrieved from the backend.
                                self.newImage = UIImage(data: imageData)!
                                self.userAvatar.image = self.newImage
                                print("Image is there, got data.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Image picking method.
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        print("User is picking an image.")
        self.dismissViewControllerAnimated(true, completion: nil)
        userAvatar.image? = image
        // Setting the user Id to the current user ID. Forcing the unwrap because there's always a current user.
        PFUser.currentUser()!["userId"] = PFUser.currentUser()!.objectId!
        // Creating the data files from the picture chosen to upload it to the backend.
        let imageData = UIImagePNGRepresentation(userAvatar.image!)
        let imageFile = PFFile(name:"image.png", data:imageData!)
        PFUser.currentUser()!["imageFile"] = imageFile
        PFUser.currentUser()!.saveInBackgroundWithBlock { (success, error) -> Void in
            // Uploads the data as imageFile to the (current) User Object.
            if error == nil {
                print("Success uploading pic with ID \(PFUser.currentUser()!.objectId!)")
                // Shows alerts if it succesfully uploaded the data.
                let imageUploadSuccess = UIAlertController(title: "Success", message:
                    "Your peepture was succesfully uploaded", preferredStyle: UIAlertControllerStyle.Alert)
                imageUploadSuccess.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
                self.presentViewController(imageUploadSuccess, animated: true, completion: nil)
                
            } else {
                // Shows alerts if it coudln't upload data by any reason.
                let imageUploadError = UIAlertController(title: "Uh-Oh!", message:
                    "Couldn't upload your peepture, please try again.", preferredStyle: UIAlertControllerStyle.Alert)
                    imageUploadError.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
                    self.presentViewController(imageUploadError, animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func changePeepture(sender: AnyObject) {
        // Changes user picture.
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        // We can only choose images from the user library.
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = true
        // Presents the "Choose an image" view.
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    

  }