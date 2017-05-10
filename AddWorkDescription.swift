//
//  AddWorkDescription.swift
//  This file contains information about the work to be done Like description of work & cost and also define if there was some components used.
//

import Foundation
import UIKit

class AddWorkDescription: CustomViewController, TextFieldCustomDelegate {
    
    // MARK: - OUTLET DECLARATION
    @IBOutlet weak var mainScrollView               : UIScrollView!
    @IBOutlet weak var descTxtView                  : UITextView!
    @IBOutlet weak var titleTxtField                : ExtendedTextField!
    @IBOutlet weak var priceTxtField                : ExtendedTextField!
    @IBOutlet weak var titleLbl                     : UILabel!
    @IBOutlet weak var deleteBtn                    : UIButton!
    @IBOutlet weak var bottomConstraintOfSaveBtn    : NSLayoutConstraint!
    
    // MARK: - VARIABLE AND CONSTANTS DECLARATION
    fileprivate var objWorkDescription              : WorkDescription!
    var workDescriptionDict                         : NSMutableDictionary!
    var isComingFromTicketWorkDescView              = false
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        
        // Set Custom delegate to extended textfields.
        self.titleTxtField.customDelegate = self
        self.priceTxtField.customDelegate = self
        
        // Customize textfield placeholder by appending current selected currency symbol.
        self.priceTxtField.placeholder = "Price " + (Global.macros.currencySymbol as String)
        
        // Adjust view according to device orientation.
        self.rotated()
        
        // Set tap gesture on view to handle operation on touch.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.resignKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        // Check whether view is moved to edit work description or to insert to work description.
        if(self.workDescriptionDict != nil) {
            
            // Populate data if view is moved to edit information.
            if (self.workDescriptionDict["work_description"] != nil) {
                
                self.descTxtView.text = self.workDescriptionDict["work_description"] as? String
            }
            
            if (self.workDescriptionDict["title"] != nil) {
                
                self.titleTxtField.text = self.workDescriptionDict["title"] as? String
            }
            
            if (self.workDescriptionDict["price"] != nil) {
                
                let price = self.workDescriptionDict["price"] as? NSString
                self.priceTxtField.text = NSString(format:"%.2f", (price?.floatValue)!) as String
            }
            
            // Set navigation header title according to edit operation.
            self.titleLbl.text = "Edit Work Description"
            self.deleteBtn.setTitle("Delete", for: UIControlState())
            
            // if view is moved from ticket work description then the opertion is going to insert work description.
            if(self.isComingFromTicketWorkDescView == true) {
                
                self.workDescriptionDict = nil
                self.titleLbl.text = "Add New Work Description"
                self.deleteBtn.setTitle("Clear", for: UIControlState())
            }
        }
        else {
            
            self.titleLbl.text = "Add New Work Description"
            self.deleteBtn.setTitle("Clear", for: UIControlState())
        }
        // Register notification to detect keyboard opening and closing.
        Manager.sharedInstance.notifyWhenKeyboardShow(self, selector: #selector(self.keyboardDidShow(_:)))
        Manager.sharedInstance.notifyWhenKeyboardHide(self, selector: #selector(self.keyboardWillHide(_:)))
        Manager.sharedInstance.notifyWhenKeyboardFrameChanged(self, selector: #selector(self.keyboardFrameChanged(_:)))
        
        // Register notification to detect device orientation.
        Manager.sharedInstance.addOrientationNotification(self, selector: #selector(self.rotated))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        Manager.sharedInstance.removeOrientationNotification(self)
        Manager.sharedInstance.removeKeyboardNotification(self)
    }
    
    // MARK: - Keyboard Notification
    // Handle keyboard notificationwhen keyboard open
    func keyboardDidShow(_ notification: Notification) {
        
        // Adjust view in landcsape orientation.
        if(self.view.frame.size.width > self.view.frame.size.height) {
            
            let tmpButton = self.view.viewWithTag(10) as? UIButton
            self.mainScrollView.contentSize = CGSize(width: 0, height: (tmpButton?.frame.origin.y)! + (tmpButton?.frame.size.height)! + 160)
        }
        
        // Adjust view for textview if it is first responder.
        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if(frame.origin.y < self.view.frame.size.height) {
            
            if(self.view.frame.size.width>self.view.frame.size.height) {// landscape mode
                
                self.bottomConstraintOfSaveBtn.constant = frame.origin.y - (self.mainScrollView.frame.origin.y + 47)
            }
            else {
                // Portrait mode
                self.bottomConstraintOfSaveBtn.constant = frame.origin.y - (self.mainScrollView.frame.origin.y + 47)
            }
        }
    }
    
    // handle keyboard notification when keyboard frame changed
    func keyboardFrameChanged(_ notification: Notification) {
        
        // Adjust view for textview if it is first responder.
        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if(frame.origin.y < self.view.frame.size.height) {
            
            if(self.view.frame.size.width>self.view.frame.size.height) {
                // landscape mode
                self.bottomConstraintOfSaveBtn.constant = frame.origin.y - (self.mainScrollView.frame.origin.y + 47)
            }
            else {
                // portrait mode.
                self.bottomConstraintOfSaveBtn.constant = frame.origin.y - (self.mainScrollView.frame.origin.y + 47)
            }
        }
    }
    
    // Handle keyboard notification when keyboard closed.
    func keyboardWillHide(_ notification: Notification) {
        
        self.bottomConstraintOfSaveBtn.constant = 15
        let tmpButton = self.view.viewWithTag(10) as? UIButton
        self.mainScrollView.contentSize = CGSize(width: 0, height: (tmpButton?.frame.origin.y)! + (tmpButton?.frame.size.height)!)
        self.mainScrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    // MARK: - API Call
    func callAddWorkDescriptionService() {
        
        // Check text validations.
        if validateFields() {
            
            // Create Dictionary of paramaters.
            var postDict = NSMutableDictionary()
            
            let price = NSString(format:"%.2f", ((self.priceTxtField.text! as String) as NSString).floatValue)
            
            postDict.setValue(price,forKey: "price")
            postDict.setValue(self.titleTxtField.text,forKey: "title")
            postDict.setValue(Global.macros.currentlyloggedInUserID,forKey: "user_id")
            postDict.setValue(self.descTxtView.text,forKey: "description")
            postDict.setValue("0",forKey: "downloaded_status")
            
            // Show activity indicator.
            self.pleaseWait()
            
            // Make Service call with url and paramaters to add work description.
            ServerCommunication.sharedInstance.postService({ (responseObject) -> Void in
                
                // Remove activity indicator
                self.clearAllNotice()
                
                // Get status code and response returned from server.
                let (statusCode,responseDict) = ServerCommunication.sharedInstance.parseResponse(responseObject! as AnyObject)
                
                // Success if status code is 1.
                if(statusCode == 1) {
                    
                    // Make further implementation on main thread.
                    DispatchQueue.main.async(execute: {
                        
                        postDict = NSMutableDictionary()
                        let price = NSString(format:"%.2f", ((self.priceTxtField.text! as String) as NSString).floatValue)
                        
                        postDict.setValue(price,                                        forKey: "price")
                        postDict.setValue("0",                                          forKey: "sync_status")
                        postDict.setValue(self.titleTxtField.text,                      forKey: "title")
                        postDict.setValue(Global.macros.currentlyloggedInUserID,        forKey: "user_id")
                        postDict.setValue(self.descTxtView.text,                        forKey: "work_description")
                        postDict.setValue(responseDict!["id"],                          forKey: "work_descp_id")
                        postDict.setValue("0",                                          forKey: "downloaded_status")
                        
                        // Insert data into local database.
                        CoreDataHelper.insertWorkDescriptionData(postDict)
                        
                        // Notify user regarding the server response.
                        Global.sharedInstance.showToast("Work Description Added Successfully")
                        
                        // move back to previous view after saving data.
                        _ = self.navigationController?.popViewController(animated: true)
                    })
                }
                else {
                    // Show Toast
                    if(responseDict!["response_message"] != nil && responseDict!["response_message"] as? String != "") {
                        
                        Global.sharedInstance.showToast((responseDict!["response_message"] as? NSString)!)
                    }
                    else {
                        // Show error message if service failues to get response.
                        Global.sharedInstance.showToast("Service error")
                    }
                }
                
            }, error_block: {(responseError) in
                
                // Show error message to user if there is any error occured.
                Global.sharedInstance.showToast("Service error")
                // remove activity indicator from view.
                self.clearAllNotice()
                
            }, paramDict: postDict, is_synchronous: false, url: Global.macros.AddGeneralWorkDescriptionAPI)
        }
    }
    
    func callEditWorkDescriptionService() {
        
        // Check text validations.
        if self.validateFields() {
            
            // Create Dictionary of paramaters.
            var postDict = NSMutableDictionary()
            
            let price = NSString(format:"%.2f", ((self.priceTxtField.text! as String) as NSString).floatValue)
            postDict.setValue(price,forKey: "price")
            postDict.setValue(self.titleTxtField.text,forKey: "title")
            postDict.setValue(Global.macros.currentlyloggedInUserID,forKey: "user_id")
            postDict.setValue(self.descTxtView.text,forKey: "description")
            postDict.setValue(self.workDescriptionDict["downloaded_status"] as? String,forKey: "downloaded_status")
            postDict.setValue(self.workDescriptionDict["work_descp_id"] as? String, forKey: "id")
            
            // Show activity indicator.
            self.pleaseWait()
            
            // Make Service call with url and paramaters to edit work description.
            ServerCommunication.sharedInstance.postService({ (responseObject) -> Void in
                
                // Remove activity indicator
                self.clearAllNotice()
                
                // Get status code and response returned from server.
                let (statusCode,responseDict) = ServerCommunication.sharedInstance.parseResponse(responseObject! as AnyObject)
                
                // Success if status code is 1.
                if(statusCode == 1) {
                    
                    // Make further implementation on main thread.
                    DispatchQueue.main.async(execute: {
                        
                        postDict = NSMutableDictionary()
                        let price = NSString(format:"%.2f", ((self.priceTxtField.text! as String) as NSString).floatValue)
                        
                        postDict.setValue(price,                                                    forKey: "price")
                        postDict.setValue("0",                                                      forKey: "sync_status")
                        postDict.setValue(self.titleTxtField.text,                                  forKey: "title")
                        postDict.setValue(Global.macros.currentlyloggedInUserID,                    forKey: "user_id")
                        postDict.setValue(self.descTxtView.text,                                    forKey: "work_description")
                        postDict.setValue(self.workDescriptionDict["work_descp_id"] as? String,     forKey: "work_descp_id")
                        postDict.setValue(self.workDescriptionDict["downloaded_status"] as? String, forKey: "downloaded_status")
                        
                        // Update data in local database.
                        CoreDataHelper.insertWorkDescriptionData(postDict)
                        
                        // Notify user regarding the server response.
                        Global.sharedInstance.showToast("Work Description updated Successfully")
                        
                        // move back to previous view after saving data.
                        _ = self.navigationController?.popViewController(animated: true)
                    })
                }
                else {
                    if(responseDict!["response_message"] != nil && responseDict!["response_message"] as? String != "") {
                        
                        Global.sharedInstance.showToast((responseDict!["response_message"] as? NSString)!)
                    }
                    else {
                        // Show error message if service failues to get response.
                        Global.sharedInstance.showToast("Service error")
                    }
                }
                
            }, error_block: {(responseError) in
                
                // Show error message to user if there is any error occured.
                Global.sharedInstance.showToast("Service error")
                
                // remove activity indicator from view.
                self.clearAllNotice()
                
            }, paramDict: postDict, is_synchronous: false, url: Global.macros.EditGeneralWorkDescriptionAPI)
        }
    }
    
    func callDeleteWorkDescriptionService() {
        
        // Make string of work description id to delete wrok description from server.
        let str = workDescriptionDict["work_descp_id"]! as! String
        
        // Show activity indicator.
        self.pleaseWait()
        
        // Append string into url with user id.
        let APIStr = Global.macros.DeleteGeneralWorkDescriptionAPI + "/user_id/\(Global.macros.currentlyloggedInUserID)/id/\(str)"
        
        // Make service call to hit data on server.
        ServerCommunication.sharedInstance.postService({ (responseObject) -> Void in
            
            // Remove activity indicator from server
            self.clearAllNotice()
            
            // Get status code and response returned from server.
            let (statusCode,responseDict) = ServerCommunication.sharedInstance.parseResponse(responseObject! as AnyObject)
            
            // Success if status code is 1.
            if(statusCode == 1) {
                
                // Make further implementation on main thread.
                DispatchQueue.main.async(execute: {
                    
                    // Delete selected work description data from local database.
                    CoreDataHelper.deleteWorkDesc(self.workDescriptionDict["work_descp_id"] as! String)
                    
                    // Notify user about data deleted.
                    Global.sharedInstance.showToast("Work Description deleted Successfully")
                    
                    // move back to previous view.
                    _ = self.navigationController?.popViewController(animated: true)
                })
            }
            else {
                if(responseDict!["response_message"] != nil && responseDict!["response_message"] as? String != "") {
                    
                    Global.sharedInstance.showToast((responseDict!["response_message"] as? NSString)!)
                }
                else {
                    // Show error message if service failues to get response.
                    Global.sharedInstance.showToast("Service error")
                }
            }
            
        }, error_block: {(responseError) in
            
            // Show error message to user if any problem occured while getting response.
            Global.sharedInstance.showToast("Service error")
            
            // remove activity indicator.
            self.clearAllNotice()
            
        }, paramDict: nil, is_synchronous: false, url: APIStr)
    }
    
    // MARK: - Button Actions
    @IBAction func saveBtnAction(_ sender: AnyObject) {
        
        // Check whether internet connection is active or not.
        if (isInternetActive == true) {
            
            self.resignKeyboard()
            
            // Check whether data is editing or inserting on server.
            if(self.workDescriptionDict != nil) {
                
                // call edit work description service if data is edited.
                self.callEditWorkDescriptionService()
            }
            else {
                // Call insert work description service if data is inserting to database.
                self.callAddWorkDescriptionService()
            }
        }
        else {
            
            // If internet connection is not active then save data in offline mode.
            let postDict = NSMutableDictionary()
            
            let price = NSString(format:"%.2f", ((self.priceTxtField.text! as String) as NSString).floatValue)
            
            postDict.setValue(price,                                        forKey: "price")
            postDict.setValue(self.titleTxtField.text,                      forKey: "title")
            postDict.setValue(self.descTxtView.text,                        forKey: "work_description")
            postDict.setValue(Global.macros.currentlyloggedInUserID,        forKey: "user_id")
            postDict.setValue(Manager.sharedInstance.offlineID(),           forKey: "work_descp_id")
            postDict.setValue("0",                                          forKey: "downloaded_status")
            postDict.setValue("0",                                          forKey: "sync_status")
            
            // Save data in local database while internet connection is offline.
            CoreDataHelper.insertWorkDescriptionData(postDict)
            
            // notify user with successfule saved data.
            Global.sharedInstance.showToast("Work Description Added Successfully")
            
            // Move back to previous view after completing operation.
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // cancel operation by pressing cancel button and move back to previous view.
    @IBAction func cancelBtnAction(_ sender: AnyObject) {
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clearBtnAction(_ sender: AnyObject) {
        
        // Check whether the data is editing or inserting.
        // show delete message if data is edited.
        if(self.workDescriptionDict != nil) {
            
            let alertController = UIAlertController(title: "E-ServiceTicket", message: "Are you sure you want to delete this part?",preferredStyle: UIAlertControllerStyle.alert)
            
            let YesBtnAction = UIAlertAction( title: "Yes", style: UIAlertActionStyle.default) { (action) in
                
                // Call delete work description service if user choose Yes option from alert.
                self.callDeleteWorkDescriptionService()
            }
            
            let noBtnAction = UIAlertAction( title: "No", style: UIAlertActionStyle.default) { (action) in }
            // Do nothing is user choose No option from alert.
            alertController.addAction(YesBtnAction)
            alertController.addAction(noBtnAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
        else {
            
            // Show xlear message to user if data is ading first time in database.
            if(self.titleTxtField.text?.isEmpty == false || self.priceTxtField.text?.isEmpty == false || self.descTxtView.text?.isEmpty == false) {
                
                let alertController = UIAlertController(title: "E-ServiceTicket", message: "Are you sure you want to clear this Work Description?",preferredStyle: UIAlertControllerStyle.alert)
                
                let YesBtnAction = UIAlertAction( title: "Yes", style: UIAlertActionStyle.default) { (action) in
                    // clear all textfields text if user chooses Yes option.
                    self.titleTxtField.text = ""
                    self.priceTxtField.text = ""
                    self.descTxtView.text = ""
                }
                
                let noBtnAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default) { (action) in }
                // Do nothing if user choose No option.
                alertController.addAction(YesBtnAction)
                alertController.addAction(noBtnAction)
                
                // hide alert view.
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func backBtnAction(_ sender: AnyObject) {
        
        // Move back to previous view by pressing back button on tope left in screen.
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Custom Functions
    func validateFields() -> Bool{
        
        // Check textfields validation setted in xib as extended textfield.
        var trimmedString = self.titleTxtField.text!.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if(trimmedString.characters.count==0) {
            Global.sharedInstance.showToast("Title field can not be empty")
            self.titleTxtField.text = ""
            return false
        }
        
        trimmedString = descTxtView.text!.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if(trimmedString.characters.count==0) {
            
            Global.sharedInstance.showToast("Description field can not be empty")
            self.descTxtView.text = ""
            return false
        }
        
        let (status,msg) = Validate().validateField(titleTxtField)
        
        if !status{
            if msg.isEqual(to: "Empty field"){
                Global.sharedInstance.showToast("Title field can not be empty")
                return false
            }
            else if (msg.isEqual(to: "Short length text")) {
                Global.sharedInstance.showToast("Please provide atleast 3 characters for Title")
                return false
            }
        }
        
        if (self.descTxtView.text.characters.count == 0) {
            
            Global.sharedInstance.showToast("Description field can not be empty")
            return false
        }
        
        return true
    }
    
    // Called When tap on view.
    func resignKeyboard(){
        
        // End all editing in view on tap in view.
        self.view.endEditing(true)
    }
    
    // MARK: - Extended Textfield Delegate
    func didBegin(_ currentTextfield: UITextField){
        
        // Adjust view in landscape mode to make textfield visible to user in screen.
        if(self.view.frame.size.height<self.view.frame.size.width) {
            
            self.mainScrollView.contentOffset = CGPoint(x: 0, y: self.titleTxtField.frame.origin.y - 7)
        }
    }
    
    func didEnd(_ currentTextfield: UITextField){
        // Update scrollview content offset to 0 when keyboard hide.
        self.mainScrollView.contentSize = CGSize(width: 0, height: 0)
    }
    
    // Handle return key in keyboard for every textfield.
    func returnKey(_ currentTextfield: UITextField){
        
        if(self.titleTxtField.isFirstResponder) {
            self.priceTxtField.becomeFirstResponder()
        }
        else if(self.priceTxtField.isFirstResponder) {
            self.descTxtView.becomeFirstResponder()
        }
    }
    
    // Update text in textfields as user type in keyboard in phone.
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool{
        
        var txtAfterUpdate:NSString = textField.text! as NSString
        
        if (textField == self.priceTxtField) {
            
            if (string == ".") {
                if (txtAfterUpdate.range(of: ".").location != NSNotFound){
                    return false
                }
            }
            // Check whether Point is already inserted in textfield if yes then restrict user to insert second point in field.
            if (string.characters.count > 0) {
                
                if (txtAfterUpdate.range(of: ".").location != NSNotFound){
                    
                    let mArr = txtAfterUpdate.components(separatedBy: ".")
                    
                    if(mArr.count > 1) {
                        
                        if(mArr[1].characters.count >= 2){
                            
                            txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
                            
                            self.priceTxtField.text = NSString(format: "%.2f", txtAfterUpdate.floatValue) as String
                            return false
                        }
                    }
                }
            }
            
            // Restrict user to add more than length of textfield.
            txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
            
            if(txtAfterUpdate.length == 13) {
                return false
            }
        }
        return true
    }
    
    // MARK: - TextView Delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        // Update Scrollview content offset to make txtfield visible to user by using animation.
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            
            if(self.view.frame.size.height<self.view.frame.size.width) {
                // landscape mode
                self.mainScrollView.contentOffset = CGPoint(x: 0, y: self.descTxtView.frame.origin.y - 7)
            }
            else {
                // portrait mode.
                // no need to update scrollview in portrait mode.
            }
            
        }, completion: nil)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n"){
            
            // Resign textview text editing.
            self.view.endEditing(true)
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        // Adjust view in phone when textview end editing and adjust scrollview content size.
        if (self.view.frame.size.height>self.view.frame.size.width) {// portrait mode
            
            self.descTxtView.resignFirstResponder()
            
            self.mainScrollView.contentSize = CGSize(width: 0, height: 0)
            
            self.mainScrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
        else {
            // Landscape Mode
            let tmpButton = self.view.viewWithTag(10) as? UIButton
            
            self.descTxtView.resignFirstResponder()
            
            // Adjsut scrollview content size in landscape mode.
            self.mainScrollView.contentSize = CGSize(width: 0, height: (tmpButton?.frame.origin.y)! + (tmpButton?.frame.size.height)!)
            
            self.mainScrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    // MARK: - Rotation Detection
    func rotated() {
        
        // Adjsut view when device orientation changed.
        if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
            
            if(self.titleTxtField.isFirstResponder || self.priceTxtField.isFirstResponder) {
                
                // Change Scrollview content size and content offset when title or price textfield is first responder.
                let tmpButton = self.view.viewWithTag(10) as? UIButton
                self.mainScrollView.contentSize = CGSize(width: 0, height: (tmpButton?.frame.origin.y)! + (tmpButton?.frame.size.height)! + 70)
                self.mainScrollView.contentOffset = CGPoint(x: 0, y: self.titleTxtField.frame.origin.y - 7)
            }
            else if (self.descTxtView.isFirstResponder) {
                
                // Change Scrollview content size and content offset when textview is first responder.
                let tmpButton = self.view.viewWithTag(10) as? UIButton
                self.mainScrollView.contentSize = CGSize(width: 0, height: (tmpButton?.frame.origin.y)! + (tmpButton?.frame.size.height)! + 70)
                self.mainScrollView.contentOffset = CGPoint(x: 0, y: self.descTxtView.frame.origin.y - 7)
            }
        }
        else {
            
            let tmpButton = self.view.viewWithTag(10) as? UIButton
            self.mainScrollView.contentSize = CGSize(width: 0, height: (tmpButton?.frame.origin.y)! + (tmpButton?.frame.size.height)!)
            self.mainScrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    // MARK: - Gesture Delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if((touch.view!.isDescendant(of: self.descTxtView)) || (touch.view!.isDescendant(of: self.titleTxtField)) || (touch.view!.isDescendant(of: self.priceTxtField))) {
            
            return false
        }
        else{
            
            return true
        }
    }
}
