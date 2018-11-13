//
//  SettingsViewViewController.swift
//  MyTodoList
//
//  Created by tai chen on 18/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

class SettingsViewViewController: UITableViewController, IAPDelegate {

    @IBOutlet weak var footerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        (UIApplication.shared.delegate as! AppDelegate).currentVC = self
   //     tableView.separatorStyle = .none
   //     tableView.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 240.0/255.0, alpha: 1.0)
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
        print("export plist to email")
        
        var paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        print(paths)
        let folder = paths[0]
        print(folder)
        let filePath = folder + "/Preferences/" + Bundle.main.bundleIdentifier! + ".plist"
        
        /*
        if FileManager.default.fileExists(atPath: filePath) {
            print("plist exists! \(filePath)")
            if let dict = NSDictionary(contentsOfFile: filePath) {
                print(dict)
            }
        }*/
        
        /*
        let data = UserDefaults.standard.dictionaryRepresentation()
        print(data)
        */
        /*

        let testDictData = data["13.11.2018A"]
        print("test data \(testDictData)")
        
        var dict = [String:[[Any]]]()
        dict["13.11.2018A"] = testDictData as! [[Any]]
        print("now... \(dict)")
        
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            print(jsonData)
            let decoded  = try JSONSerialization.jsonObject(with: jsonData, options: [])
            print(decoded)
            
            let reconstructedDict = decoded as! [String:[[Any]]]
            print(reconstructedDict)
            
        }catch{
            print("backup error")
        }
 */
    }
    
    
}
