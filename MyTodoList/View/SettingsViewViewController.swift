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
    
}
