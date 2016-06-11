//
//  Charter.swift
//  
//
//  Created by Zhenyang Zhong on 6/9/16.
//
//

import UIKit
import FirebaseDatabase
import JSQMessagesViewController
import JSQSystemSoundPlayer

class Charter: JSQMessagesViewController {

    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    var ref = FIRDatabase.database().reference().child("Messages")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .None
        title = "Chatter"
        setupBubbles()
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        // Do any additional setup after loading the view.
        
        
    }
    
    func sortDicByKey(lhs:(key: AnyObject, value: AnyObject), rhs: (key: AnyObject, value: AnyObject)) -> Bool{
        return (lhs.key as! String) < (rhs.key as! String)
    }


    func loadMsg(){
        ref.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//            if let dic = snapshot.value as? NSDictionary{
//                let sortDic = dic.sort(self.sortDicByKey)
//                for (_, val) in sortDic{
//                    self.addMessage(val["senderId"] as! String, text: val["text"] as! String)
//                }
//                self.finishReceivingMessage()
//            }
//            print(snapshot.value)
//            var msg = snapshot.children.nextObject() as! FIRDataSnapshot
//            print(snapshot.value)
            for msg in snapshot.children.allObjects as! [FIRDataSnapshot]{
                if let dic = msg.value as? Dictionary<String, String>{
                    self.addMessage(dic["senderId"]!, text: dic["text"]!)
                }
            }
            
//            if let dic = snapshot.value as? Dictionary<String, Dictionary<String, String>>{
//                print(dic)
//                let keys = dic.keys.sort(<)
//                for key in keys{
//                    print(key)
//                    if let sender_id = dic[key]?["senderId"], let text = dic[key]?["text"]{
//                        self.addMessage(sender_id, text: text)
//                    }
//                }
//            }
            self.finishReceivingMessage()
        })
        
    }

    var userIsTypingRef: FIRDatabaseReference! // 1
    private var localTyping = false // 2
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            showTypingIndicator = newValue
            scrollToBottomAnimated(newValue)
            userIsTypingRef.setValue(newValue)
        }
    }
    
    private func observeTyping() {
        let typingIndicatorRef = FIRDatabase.database().reference().child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        isTyping = false
        
        typingIndicatorRef.observeEventType(.Value, withBlock:  { (snapshot) in
//            print(snapshot.value)
//            if let typing = snapshot.value as? Bool{
//                self.showTypingIndicator = typing
//                self.scrollToBottomAnimated(true)
//            }
            for user in snapshot.children.allObjects as! [FIRDataSnapshot]{
                if user.key != self.senderId{
                    if user.value as! Bool{
                        self.isTyping = true
                    }
                    else {
                        self.isTyping = false
                    }
                }
            }
        })
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
//        print(textView.text)
        isTyping = textView.text != ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // bubble
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId{
            return outgoingBubbleImageView
        }
        else {
            return incomingBubbleImageView
        }
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    func addMessage(id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: senderDisplayName, text: text)
        messages.append(message)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // animates the receiving of a new message on the view
        loadMsg()
        observeTyping()
        finishReceivingMessage()
    }
    
    // text color
    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        addMessage(senderId, text: text)
        let msgRef = ref.childByAutoId()
        msgRef.child("senderId").setValue(senderId)
        msgRef.child("text").setValue(text)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
    }
}