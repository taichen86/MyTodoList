//
//  ListViewController.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit

extension ListViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // TODO: optimise!
        textView.sizeToFit()
        tableView.beginUpdates()
        tableView.endUpdates()
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
   //     print("did begin editing \(textView.tag)")
        itemBeingEdited = textView.tag
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("did end editing \(textView.tag)")
        textView.text = textView.text.trimmingCharacters(in: .whitespaces)
        if textView.tag < todos.count {
        print("edit existing \(textView.tag)")
            todos[textView.tag] = textView.text
            if textView.text.isEmpty {
                deleteItem(index: textView.tag)
            }
        }else{
            // check for empty entry
            if !textView.text.isEmpty {
                todos.append(textView.text)
                print("add new item \(textView.tag)")
            }else{
                print("empty string, no add")
            }
        }
        saveList()
    }
  
}

class ListViewController: UITableViewController {

    
    @IBOutlet weak var defaultText: UILabel!
    var todos = ["todo item 1"] // update this from user defaults
    
    var list = "Daily"
    let dateFormatter = DateFormatter()
    let userdefaults = UserDefaults.standard
    var listKey = "list" // Daily 01.12.2018, Weekly 01.12.2018, Monthly 10.2018
    var itemBeingEdited = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: disable textfields by default
  //      view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
  //      NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
  //      NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        // show date
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let date = dateFormatter.string(from: Date())
        navigationItem.title = date
        listKey = "daily \(date)"
        
        if let content = userdefaults.array(forKey: listKey) {
            print("existing data for \(listKey)")
            todos = content as! [String]
        }
        
        // number of rows to fill screen
        numOfRows = todos.count
        if numOfRows > 0 {
            defaultText.frame.size.height = 0
        }
        addEmptyRows()
        refreshTableView()
    }
    
    
    func deleteItem(index: Int) {
        print("delete item \(index)")
        todos.remove(at: index)
        print(todos)
        saveList()
        refreshTableView()
    }
    
    func saveList() {
        print("save list \(listKey)")
        print(todos)
        userdefaults.set(todos, forKey: listKey)
    }
    
    @objc func keyboardWillShow() {
        print("keyboard up")
    }
    
    @objc func keyboardWillHide() {
        print("keyboard down")
    }

    
    
    
    
    // MARK: - Table view
    func refreshRowHeight() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100.0
        //     tableView.rowHeight = 100.0
    }
    
    func refreshTableView() {
        print("refreshtableview")
        tableView.reloadData()
        refreshRowHeight()
    }
    
    // MARK: - Table view selection row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
   //     print("select row \(indexPath.row)")
        // edit next cell
        let cell = tableView.cellForRow(at: IndexPath(row: todos.count, section: 0)) as! TodoItemCell
 //       print("enable row \(todos.count)")
        cell.textView.isUserInteractionEnabled = true
        cell.textView.becomeFirstResponder()
        
    }


    // MARK: - Table view initialization
    var cellHeight = CGFloat(44.0)
    var numOfRows = 0
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
   //    print("num of rows \(numOfRows)")
        return numOfRows
    }

    func addEmptyRows() {
        var rows = 3
        let diff = UIScreen.main.bounds.height -  tableView.contentSize.height
        let cheight = cellHeight + 20.0 // top bottom padding
        if diff >  CGFloat(3.0) * cheight  {
            rows = Int(diff/cheight)
        }
        numOfRows += rows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath) as! TodoItemCell
        cellHeight = cell.frame.height
        if indexPath.row < todos.count {
            print(todos[indexPath.row])
            cell.textView.text = todos[indexPath.row]
            cell.textView.isUserInteractionEnabled = true
        }else{
            cell.textView.text = ""
        }
        
        cell.tableView = self
        cell.textView.tag = indexPath.row
        cell.textView.delegate = self

  //      print(cell.textView.text)
        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }*/

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
