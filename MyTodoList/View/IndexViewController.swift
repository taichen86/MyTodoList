//
//  ViewController.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

enum ListType {
    case daily
    case monthly
    case yearly
}

class IndexViewController: UITableViewController {

    
    var items = ["Daily", "Weekly", "Monthly"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "IndexItemCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    var listSelected = 0
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        listSelected = indexPath.row
        print("selected list \(items[listSelected])")
        performSegue(withIdentifier: "goToList", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ListViewController {
            vc.list = items[listSelected]
        }
    }

}



