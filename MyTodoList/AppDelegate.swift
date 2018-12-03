//
//  AppDelegate.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        IAP.instance.fetchProducts()
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        do{
            let data = try Data(contentsOf: url)
            var editedDict = [String:[[Any]]]()

            if let dict = NSDictionary(contentsOf: url) as? [String:Any]{
                for list in dict {
                    if let items = list.value as? [[Any]]{
                        if items.count > 0 {
                            editedDict[list.key] = items
                        }
                    }
                }

                for backupList in editedDict {
                    var newList = [[Any]]()
                    if let existingList = UserDefaults.standard.object(forKey: backupList.key) as? [[Any]] {
                        newList = existingList
                    }
                    
                    for backupItem in backupList.value {
                        newList.append(backupItem)
                    }
                    UserDefaults.standard.set(newList, forKey: backupList.key)
                }
            }
            
            let name = Notification.Name(rawValue: "importcompletednotification")
            NotificationCenter.default.post(name: name, object: nil)
            

        }catch{
            let name = Notification.Name(rawValue: "importerrornotification")
            NotificationCenter.default.post(name: name, object: nil)
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

