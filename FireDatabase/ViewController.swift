//
//  ViewController.swift
//  FireDatabase
//
//  Created by Zhenyang Zhong on 6/5/16.
//  Copyright © 2016 Zhenyang Zhong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Photos
import JSQMessagesViewController

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var info1: UITextField!
    
    @IBOutlet weak var info2: UITextField!
    
    @IBAction func showImage(sender: AnyObject) {
//        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
//        let documentsDirectory = paths[0]
//        let savePath = "file:\(documentsDirectory)/myimage.jpg"
//        let storagePath = NSUserDefaults.standardUserDefaults().objectForKey("storagePath") as! String
        storageRef.child(filePath).downloadURLWithCompletion { (url, error) in
            if let error = error{
                print(error)
            }
            else {
                print("download succeed!")
                print(url)
                self.imageView.image = UIImage(data: NSData(contentsOfURL: url!)!)
                
                
            }
        }
//        storageRef.child(storagePath).writeToFile(NSURL.fileURLWithPath(savePath), completion: {(url, error) in
//            if let error = error{
//                print("Error downloading:\(error)")
//            }
//            else {
//                print("Download Succeeded!")
//                self.imageView.image = UIImage.init(contentsOfFile: savePath)
//            }
//        })
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    var ref:FIRDatabaseReference!
    var storageRef:FIRStorageReference!
    var storage:FIRStorage!
    
    @IBAction func signup(sender: AnyObject) {
        FIRAuth.auth()?.createUserWithEmail(email.text!, password: password.text!, completion: { (user, error) in
            if error == nil{
                if let user = user{
                    print("signup successfully")
                    print(user.email)
                }
                else{
                    print("user not found")
                }
            }
            else {
                print("signup fail")
                print(error?.localizedDescription)
            }
        })
    }
    
    @IBAction func signin(sender: AnyObject) {
        FIRAuth.auth()?.signInWithEmail(email.text!, password: password.text!, completion: { (user, error) in
            if error == nil{
                if let user = user{
                    print("login successfully")
                    print(user.email)
                    let board = UIStoryboard(name: "Main", bundle: nil)
                    let vc = board.instantiateViewControllerWithIdentifier("nav") as! UINavigationController
                    let chatter = vc.viewControllers.first as! Charter
                    chatter.senderId = user.uid
                    chatter.senderDisplayName = user.email
                    self.showViewController(vc, sender: nil)
                }
                else {
                    print("user not found")
                }
            }
            else {
                print(error?.localizedDescription)
            }
        })
    }
    
    @IBAction func confirm(sender: AnyObject) {
//        let arr = ["iPhone", "Mac", "iPad", "iPod", "Macbook", "appleTV", "appleWatch"]
//        ref.child("Tech Company").child("Apple").setValue(arr)
//        let dataRef = ref.child("Tech Company").child("Google").childByAutoId()
//        print(dataRef.key)
//        dataRef.setValue("Android")
        
        
//        let postRef = ref.child("Tech Company").child("Apple")
//        postRef.runTransactionBlock { (currData) -> FIRTransactionResult in
//            if currData.value != nil && currData.value is NSArray{
//                var data = currData.value as! [String]
//                data.append("iOS")
//                currData.value = data
//            }
//            return FIRTransactionResult.successWithValue(currData)
//        }
        
//        let refHandle = ref.observeEventType(.Value, withBlock: { (snapshot) in
//            let postDict = snapshot.value as! [String : AnyObject]
//            print(postDict)
//        })
        
//        let google = ref.child("Tech Company").child("Google")
//        google.childByAutoId().setValue("Youtube")
//        google.childByAutoId().setValue("Google Apps")
//        google.childByAutoId().setValue("Cardboard")
//        google.childByAutoId().setValue("Firebase")
//        google.childByAutoId().setValue("Google Glasses")
        
//        google.queryOrderedByValue().observeSingleEventOfType(.Value, withBlock: block)
//        
//        let google = ref.child("Tech Company").child("Google")
//        google.queryOrderedByKey().queryStartingAtValue("-KJYrr6JCOzqK708YFBj").observeSingleEventOfType(.Value, withBlock: block)

        let picker = UIImagePickerController()
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    let block = { (snapshot:FIRDataSnapshot) in
        if let postDict = snapshot.value as? NSDictionary{
            let dict = postDict.reverse()
            for (key, val) in dict{
                print(key,val)
            }
            print(postDict)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let referenceURL = info[UIImagePickerControllerReferenceURL]{
            let assets = PHAsset.fetchAssetsWithALAssetURLs([referenceURL as! NSURL], options: nil)
            let asset = assets.firstObject
            asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInfo, info) in
                let imageFile = contentEditingInfo?.fullSizeImageURL
                self.filePath = FIRAuth.auth()!.currentUser!.uid + "/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))/\(imageFile!.lastPathComponent!)"
                self.storageRef.child(self.filePath)
                    .putFile(imageFile!, metadata: nil, completion: { (metadata, error) in
                        if let error = error{
                            print("Error uploading: \(error)")
                            print("Upload Failed")
                            return
                        }
                        else {
                            print("upload sucessfully")
//                            NSUserDefaults.standardUserDefaults().setObject(filePath, forKey: "storagePath")
//                            NSUserDefaults.standardUserDefaults().synchronize()
                        }
                    })
            })
        }
    }
    
    var filePath:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ref = FIRDatabase.database().reference()
        
        storageRef = FIRStorage.storage().reference()
        storage = FIRStorage.storage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

