//
//  SettingsViewViewController.swift
//  MyTodoList
//
//  Created by tai chen on 18/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit
import MessageUI

class SettingsViewViewController: UITableViewController, IAPDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var footerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = footerView
        upgradeButton.titleLabel?.numberOfLines = 2
        upgradeButton.titleLabel?.lineBreakMode = .byWordWrapping
        if IAP.instance.products.count > 0 {
            setIAP()
        }else{
            print("no products yet")
        }
        
        IAP.instance.iapDelegate = self
        
    }
    
    // MARK: - in app purchase
    func setIAP () {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = IAP.instance.products[0].priceLocale
        upgradeButton.setTitle(IAP.instance.products[0].localizedDescription + " " + formatter.string(from: IAP.instance.products[0].price)!, for: .normal)
    }
    
    @IBOutlet weak var upgradeButton: UIButton!
    @IBAction func upgradeButtonPressed(_ sender: UIButton) {
        if IAP.instance.canMakePayment() {
            IAP.instance.purchase()
        }else{
     //       print("user cannot make payment")
            let alert = UIAlertController(title: "error", message: "your account is not configured to make payments", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        }
    }
    
    @IBAction func restoreButtonPressed(_ sender: UIButton) {
        IAP.instance.restorePurchases()
    }
    
    func restoreSuccessAlert() {
        let alert = UIAlertController(title: "success", message: "purchase restored", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - data backup
    @IBAction func backupPressed(_ sender: UIButton) {
        
        var paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let folder = paths[0]
        let filePath = folder + "/Preferences/" + Bundle.main.bundleIdentifier! + ".plist"
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setSubject("Daily Todo List backup data")
        mailComposer.setMessageBody("This file contains the backup data of your Daily Todo List app. To import this data to your Daily Todo List app, simply open this file (long press and select Copy to TodoList) on your phone. You need to have the app installed and updated for this to work.", isHTML: false)
        do{
            let data = try NSData(contentsOfFile: filePath) as Data
            mailComposer.addAttachmentData(data, mimeType: "application/xml", fileName: "DailyTodoListData.tpb")
            present(mailComposer, animated: true, completion: nil)
        }catch{
           let alert = UIAlertController(title: "error", message: "Your data could not be backed up. Please contact the developer.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    

    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
}
