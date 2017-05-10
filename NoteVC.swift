//
//  NoteVC.swift
//  This file contains basic information about job status. This screen pop ups after the job has been completed. And Technician can put notes like if there is any  breakage or any part of job pending etc..



import UIKit

class NoteVC: CustomViewController , UITextViewDelegate , UIGestureRecognizerDelegate{
    
    // MARK: - OUTLET DECLARATION
    @IBOutlet weak var bottomConstraint     : NSLayoutConstraint!
    @IBOutlet weak var txtView              : UITextView!
    
    // MARK: - VARIABLE AND CONSTANTS DECLARATION
    var ticketId                            : String!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.txtView.delegate = self
        
        // Add Tap gesture on main view to handle touch on view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        // Get notes about service ticket from local database if saved and populate its data in textview.
        var dict = NSMutableDictionary()
        
        if let mArr = userDefault.object(forKey: "WorkNotes") {
            
            let predicate = NSPredicate(format: "user_id = %@ AND ticket_id = %@", Global.macros.currentlyloggedInUserID, self.ticketId)
            
            let filteredArray = (mArr as! NSArray).filtered(using: predicate)
            
            if(filteredArray.count > 0) {
                
                dict = filteredArray[0] as! NSMutableDictionary
            }
        }
        else {
            
            dict = CoreDataHelper.getNoteTableData(self.ticketId as NSString)
        }
        
        self.txtView.text = dict["note"] as? String
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Add Keyboard notitfication to detect keyboard visibility on screen.
        Manager.sharedInstance.notifyWhenKeyboardShow(self, selector: #selector(self.keyboardDidShow(_:)))
        Manager.sharedInstance.notifyWhenKeyboardHide(self, selector: #selector(self.keyboardWillHide(_:)))
        Manager.sharedInstance.notifyWhenKeyboardFrameChanged(self, selector: #selector(self.keyboardFrameChanged(_:)))        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        var mainArr = NSMutableArray()
        let localDict = NSMutableDictionary()
        
        localDict.setValue(self.txtView.text,                       forKey: "note")
        localDict.setValue(self.ticketId,                           forKey: "ticket_id")
        localDict.setValue(Global.macros.currentlyloggedInUserID,   forKey: "user_id")
        
        if let mArr = userDefault.object(forKey: "WorkNotes") {
            
            mainArr = (mArr as! NSArray).mutableCopy() as! NSMutableArray
            
            let predicate = NSPredicate(format: "user_id = %@ AND ticket_id = %@", Global.macros.currentlyloggedInUserID, self.ticketId)
            
            let filteredArray = mainArr.filtered(using: predicate)
            
            if(filteredArray.count > 0) {
                
                let index = mainArr.index(of: filteredArray[0])
                mainArr.replaceObject(at: index, with: localDict)
            }
            else {
                mainArr.add(localDict)
            }
            
            userDefault.set(mainArr, forKey: "WorkNotes")
        }
        else {
            
            mainArr.add(localDict)
            userDefault.set(mainArr, forKey: "WorkNotes")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        // Remove Keyboard notification before leaving from view.
        Manager.sharedInstance.removeKeyboardNotification(self)
    }
    
    // MARK: - Keyboard Notification
    func keyboardDidShow(_ notification: Notification) {
        
        let info  = (notification as NSNotification).userInfo!
        let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]! as AnyObject
        
        let rawFrame = value.cgRectValue
        let keyboardFrame = view.convert(rawFrame!, from: nil)
        if(UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
            
            self.bottomConstraint.constant = self.view.frame.height - (keyboardFrame.height+40)
        }
        else{
            
            self.bottomConstraint.constant = self.view.frame.height - (keyboardFrame.height+180)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        
        self.bottomConstraint.constant = 40
    }
    
    func keyboardFrameChanged(_ notification: Notification) {
        
    }
    
    func handleTap(_ sender:UITapGestureRecognizer){
        
        self.view.endEditing(true)
    }
    
    // MARK: - Button Actions
    @IBAction func saveBtnAction(_ sender: AnyObject) {
        
        // Check Textview text validation before saving procedure starts.
        if(self.validateFields()) {
            
            self.view.endEditing(true)
            
            // Show activity indicator on screen to let the user know that saving is in progress.
            self.pleaseWait()
            
            // Call Service to save notes on server.
            self.callAddNotesService()
        }
    }
    
    @IBAction func deleteBtnAction(_ sender: AnyObject) {
        
        if(self.txtView.text.isEmpty == false) {
            
            // Show alert message to user to confirm is he sure to delete note or not.
            let alertController = UIAlertController(title: "E-ServiceTicket", message: "Are you sure you want to delete the Note?",preferredStyle: UIAlertControllerStyle.alert)
            
            let YesBtnAction = UIAlertAction( title: "Yes", style: UIAlertActionStyle.default) { (action) in
                // Call Service if user confirm it by Yes.
                DispatchQueue.main.async(execute: {
                    
                    self.pleaseWait()
                    
                    self.callDeleteNotesService()
                })
            }
            
            // Do nothing is user chooses No option.
            let noBtnAction = UIAlertAction( title: "No", style: UIAlertActionStyle.default) { (action) in }
            
            alertController.addAction(YesBtnAction)
            alertController.addAction(noBtnAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func clearbtnAction(_ sender: AnyObject) {
        
        if(self.txtView.text.isEmpty == false) {
            
            // Show alert message to user to confirm is he sure to delete note or not.
            let alertController = UIAlertController(title: "E-ServiceTicket", message: "Are you sure you want to clear the Note?",preferredStyle: UIAlertControllerStyle.alert)
            
            let YesBtnAction = UIAlertAction( title: "Yes", style: UIAlertActionStyle.default) { (action) in
                // Clear textview text if user chooses yes option other do nothing.
                DispatchQueue.main.async(execute: {
                    
                    self.txtView.text = ""
                })
            }
            
            let noBtnAction = UIAlertAction( title: "No", style: UIAlertActionStyle.default) { (action) in }
            
            alertController.addAction(YesBtnAction)
            alertController.addAction(noBtnAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Call Note Service
    func callAddNotesService() {
        
        // Make dictionary if service tickets.
        let postDict = self.makeDictionary(true)
        
        // Make call of service.
        ServerCommunication.sharedInstance.postService({ (responseObject) -> Void in
            
            // Remove activity indicator when response recieved.
            self.clearAllNotice()
            
            // Parse response code and response dictionary returned from server.
            let (statusCode, responseDict) = ServerCommunication.sharedInstance.parseResponse(responseObject! as AnyObject)
            
            // Success if response code is 1.
            if(statusCode == 1) {
                
                // Get main thread to make changes on screen.
                DispatchQueue.main.async(execute: {
                    
                    // Show successful message to user.
                    Global.sharedInstance.showToast("Note updated successfully")
                    
                    // Save note data in local database.
                    CoreDataHelper.saveNoteTableData(postDict)
                    
                    // Move back to previous view.
                    _ = self.navigationController?.popViewController(animated: true)
                })
            }
            else {
                // If status code is 0, then show message returned from server.
                if(responseDict!["response_message"] != nil && responseDict!["response_message"] as? String != "") {
                    
                    Global.sharedInstance.showToast((responseDict!["response_message"] as! NSString))
                }
                else {
                    // Show error message if service failues to get response.
                    Global.sharedInstance.showToast("Service error")
                }
            }
            
            }, error_block: { (responseError) -> Void in
                
                // Show error message if service failues to get response.
                Global.sharedInstance.showToast("Service error")
                self.clearAllNotice()
                
            }, paramDict: postDict, is_synchronous: false, url: Global.macros.AddNoteAPI)
    }
    
    func callDeleteNotesService() {
        
        // Make service paramaters in dictionary form.
        let postDict = self.makeDictionary(false)
        
        // Make Service call to delete notes saved on server corressponding to selected service ticket.
        ServerCommunication.sharedInstance.postService({ (responseObject) -> Void in
            
            // Remove activity indicator when response recieved.
            self.clearAllNotice()
            
            // Parse response code and response dictionary returned from server.
            let (statusCode, responseDict) = ServerCommunication.sharedInstance.parseResponse(responseObject! as AnyObject)
            
            // Success if response code is 1.
            if(statusCode == 1) {
                
                // Get main thread to make changes on screen.
                DispatchQueue.main.async(execute: {
                    
                    // Delete note data from local database.
                    CoreDataHelper.deleteNoteTable(self.ticketId)
                    
                    // Show successful message to user.
                    Global.sharedInstance.showToast("Note deleted successfully")
                    
                    // Move back to previous view.
                    _ = self.navigationController?.popViewController(animated: true)
                })
            }
            else {
                // If status code is 0, then show message returned from server.
                if(responseDict!["response_message"] != nil && responseDict!["response_message"] as? String != "") {
                    
                    Global.sharedInstance.showToast((responseDict!["response_message"] as? NSString)!)
                }
                else {
                    // Show error message if service failues to get response.
                    Global.sharedInstance.showToast("Service error")
                }
            }
            
            }, error_block: { (responseError) -> Void in
                
                // Show error message if service failues to get response.
                Global.sharedInstance.showToast("Service error")
                self.clearAllNotice()
                
            }, paramDict: postDict, is_synchronous: false, url: Global.macros.AddNoteAPI)
    }
    
    // MARK: - Custom Functions
    func validateFields() -> Bool {
        
        if(self.txtView.text.isEmpty == true) {
            
            Global.sharedInstance.showToast("Please provide information for Note")
            return false
        }
        
        return true
    }
    
    func makeDictionary(_ addNote: Bool) -> NSMutableDictionary {
        
        // Make dictionary of service paramater.
        let postDict = NSMutableDictionary()
        
        postDict.setValue(self.ticketId, forKey: "ticket_id")
        postDict.setValue(Global.macros.currentlyloggedInUserID, forKey: "user_id")
        
        // Check whether note adding or deleting.
        if(addNote) {
            postDict.setValue(self.txtView.text, forKey: "note")
        }
        else {
            postDict.setValue("", forKey: "note")
        }
        
        return postDict
    }
    
    // MARK: - Textview Delegate
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n"){
            self.view.endEditing(true)
        }
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
