//
//  IAP.swift
//  MyTodoList
//
//  Created by tai chen on 17/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit
import StoreKit

class IAP : NSObject {
    
    static let instance = IAP()
    
    let IAP_upgrade = "com.TPBSoftware.DailyTodoList.upgrade"
    var products = [SKProduct]()
    
    func fetchProducts() {
        if products.count > 0 {
            return
        }
        print("fetch products")
        let productIDs = Set([IAP_upgrade])
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase() {
        if products.count > 0 {
            let payment = SKPayment(product: products[0])
            SKPaymentQueue.default().add(payment)
        }else{
            print("no such product")
        }
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func canMakePayment() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
}


extension IAP : SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            print("add product: \(product)")
            products.append(product)
            break
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("PURCHASED \(transaction)")
                SKPaymentQueue.default().finishTransaction(transaction)
                UserDefaults.standard.set(true, forKey: "upgrade")
            break
            case .failed:
                print("FAILED \(transaction)")
                SKPaymentQueue.default().finishTransaction(transaction)
            break
            case .restored:
            break
            default:
                break
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
