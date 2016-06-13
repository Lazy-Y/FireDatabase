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
import FirebaseAuth
import SDAutoLayout
import KRVideoPlayer

class Charter: JSQMessagesViewController{

    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    var ref = FIRDatabase.database().reference().child("Messages")
    var userRef = FIRDatabase.database().reference().child("users")
    var avatars = [String:JSQMessagesAvatarImage]()
    var videoView:KRVideoPlayerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .None
        title = "Chatter"
        setupBubbles()
        setupAvatarColor(senderId, incoming: false)
        automaticallyScrollsToMostRecentMessage = true

        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        view.addGestureRecognizer(tap)
    }
    
    func setupVideo(url:NSURL){
        let width = UIScreen.mainScreen().bounds.size.width;
        videoView = KRVideoPlayerController(frame: CGRectMake(0, 0, width, width*9/16))
        videoView.contentURL = url
    }
    
    func dismiss() {
        editing = false
    }
    
    func sortDicByKey(lhs:(key: AnyObject, value: AnyObject), rhs: (key: AnyObject, value: AnyObject)) -> Bool{
        return (lhs.key as! String) < (rhs.key as! String)
    }

    func loadMsg(){
        ref.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            for msg in snapshot.children.allObjects as! [FIRDataSnapshot]{
                if let dic = msg.value as? Dictionary<String, String>{
                    self.addMessage(dic["senderId"]!, text: dic["text"]!)
                }
            }
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
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    func sendPhoto(action:UIAlertAction){
        let photoItem = JSQPhotoMediaItem(image: UIImage(named: "CR7")!)
        let photoMsg = JSQMessage(senderId: senderId, senderDisplayName: senderId, date: NSDate(), media: photoItem)
        messages.append(photoMsg)
        finishReceivingMessage()
    }
    
    func sendLocation(action:UIAlertAction){
        weak var weakView = collectionView
        addLoction(){
            weakView?.reloadData()
        }
    }
    
    func addLoction(completion:JSQLocationMediaItemCompletionBlock) {
        let ferryBuildingInSF = CLLocation(latitude: 37.795313, longitude: -122.393757)
        let locationItem = JSQLocationMediaItem()
        locationItem.setLocation(ferryBuildingInSF, withCompletionHandler: completion)
        let locationMsg = JSQMessage(senderId: senderId, displayName: senderId, media: locationItem)
        messages.append(locationMsg)
        finishSendingMessage()
    }
    
    func sendVideo(action:UIAlertAction){
        let url = NSBundle.mainBundle().URLForResource("sherry", withExtension: "m4v")
        let video = JSQVideoMediaItem(fileURL: url, isReadyToPlay: true)
        let videoMsg = JSQMessage(senderId: senderId, displayName: senderId, media: video)
        messages.append(videoMsg)
        finishSendingMessage()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        if let video = messages[indexPath.item].media as? JSQVideoMediaItem{
            weak var weakSelf = self
            setupVideo(video.fileURL)
            videoView.dimissCompleteBlock = {
                weakSelf?.videoView = nil
            }
            videoView.showInWindow()
        }
    }
    
    func sendAudio(action:UIAlertAction){
        let sample = NSBundle.mainBundle().pathForResource("hello", ofType: "mp3")
        let audioItem = JSQAudioMediaItem(data: NSData(contentsOfFile: sample!))
        let audioMsg = JSQMessage(senderId: senderId, displayName: senderId, media: audioItem)
        messages.append(audioMsg)
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        inputToolbar.contentView.textView.resignFirstResponder()
    
        let sheet = UIAlertController(title: "Media messages", message: nil, preferredStyle: .ActionSheet)
        sheet.addAction(UIAlertAction(title: "Send photo", style: .Default, handler: sendPhoto))
        sheet.addAction(UIAlertAction(title: "Send location", style: .Default, handler: sendLocation))
        sheet.addAction(UIAlertAction(title: "Send video", style: .Default, handler: sendVideo))
        sheet.addAction(UIAlertAction(title: "Send audio", style: .Default, handler: sendAudio))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(sheet, animated: true, completion: nil)
    }
    
    private func observeTyping() {
        let typingIndicatorRef = FIRDatabase.database().reference().child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        isTyping = false
        typingIndicatorRef.observeEventType(.Value, withBlock:  { (snapshot) in
            for user in snapshot.children.allObjects as! [FIRDataSnapshot]{
                if user.key != self.senderId{
                    if user.value as! Bool{
                        self.showTypingIndicator = true
                        self.scrollToBottomAnimated(true)
                    }
                    else {
                        self.showTypingIndicator = false
                    }
                }
            }
        })
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        setupAvatarColor(message.senderId, incoming: true)
        return UIImageView(image: avatars[message.senderId]!.avatarImage)
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
        
        if let textView = cell.textView{
            if message.senderId == senderId {
                textView.textColor = UIColor.whiteColor()
            } else {
                textView.textColor = UIColor.blackColor()
            }
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
    
    func setupAvatarColor(name: String, incoming: Bool) {
        guard let _ = avatars[name] else{
            let diameter = incoming ? UInt(collectionView!.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView!.collectionViewLayout.outgoingAvatarViewSize.width)
            
            let rgbValue = name.hash
            let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
            let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
            let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
            let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
            
            let nameLength = name.characters.count
            let initials : String? = name.substringToIndex(senderId.startIndex.advancedBy(min(3, nameLength)))
            let userImage = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: color, textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(CGFloat(13)), diameter: diameter)
            avatars[name] = userImage
            return
        }
    }
    
    // View  usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item];
        // Sent by me, skip
        if message.senderId == senderId {
            return nil;
        }
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId == message.senderId {
                return nil;
            }
        }
        let attribute = NSAttributedString(string:message.senderId)
        return attribute
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        // Sent by me, skip
        if message.senderId == senderId {
            return CGFloat(0.0);
        }
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId == message.senderId {
                return CGFloat(0.0);
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
//    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
//        print("Reload")
//    }
    
}

extension UIImageView: JSQMessageBubbleImageDataSource, JSQMessageAvatarImageDataSource{
    public func messageBubbleImage() -> UIImage!{
        return image!
    }
    public func messageBubbleHighlightedImage() -> UIImage!{
        return (highlightedImage != nil) ? highlightedImage! : image!
    }
    public func avatarImage() -> UIImage{
        return image!
    }
    public func avatarHighlightedImage() -> UIImage!{
        return (highlightedImage != nil) ? highlightedImage! : image!
    }
    public func avatarPlaceholderImage() -> UIImage!{
        return image!
    }
}

