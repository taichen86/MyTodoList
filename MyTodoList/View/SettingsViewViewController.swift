//
//  SettingsViewViewController.swift
//  MyTodoList
//
//  Created by tai chen on 18/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

class SettingsViewViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if IAP.instance.products.count > 0 {
            setIAP()
        }

    }
    
    func setIAP () {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = IAP.instance.products[0].priceLocale
        upgradeLabel.setTitle(IAP.instance.products[0].localizedDescription + " " + formatter.string(from: IAP.instance.products[0].price)!, for: .normal)
    }
    
    @IBOutlet weak var upgradeLabel: UIButton!
    @IBOutlet weak var restoreLabel: UIButton!
    
    @IBAction func upgradeButtonPressed(_ sender: UIButton) {
        if IAP.instance.canMakePayment() {
            IAP.instance.purchase()
        }else{
            print("user cannot make payment")
            let alert = UIAlertController(title: "error", message: "your account is not configured to make payments", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        }
    }
    
    @IBAction func restoreButtonPressed(_ sender: UIButton) {
        IAP.instance.restorePurchases()
    }
    
}
