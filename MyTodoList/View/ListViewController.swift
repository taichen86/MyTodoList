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
        print("did begin editing \(textView.tag)")
        itemBeingEdited = textView.tag
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("did end editing \(textView.tag)")
        textView.isUserInteractionEnabled = false
        textView.text = textView.text.trimmingCharacters(in: .whitespaces)
        if textView.tag < todos.count {
        print("edit existing \(textView.tag)")
            todos[textView.tag][0] = textView.text!
            if textView.text.isEmpty {
                deleteItem(section: sectionBeingEdited, row: itemBeingEdited)
            }
        }else{
            var todo : [Any] = [""]
            if !textView.text.isEmpty {
                todo[0] = textView.text!
                todos.append(todo)
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
    var todos = [[Any]]() // 0 - text , 1 - color
    var dones = [[Any]]()
    
    var list = "Daily"
    let dateFormatter = DateFormatter()
    let userdefaults = UserDefaults.standard
    var listKey = "list" // Daily 01.12.2018, Weekly 01.12.2018, Monthly 10.2018
    var itemBeingEdited = 0
    var sectionBeingEdited = 0
    
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
        listKey = "\(date)"
        
        
        if let content = userdefaults.array(forKey: "\(listKey)todo") {
            print("existing date for todos)")
            todos = content as! [[Any]]
            print(todos)
        }
        if let content = userdefaults.array(forKey: "\(listKey)done") {
            print("existing data for dones")
            dones = content as! [[Any]]
            print(dones)
        }
        
        // number of rows to fill screen
        numOfTodoRows = todos.count
        if numOfTodoRows > 0 {
            defaultText.frame.size.height = 0
        }
        addEmptyRows()
        refreshTableView()
    }
    
    func completeItem(section: Int, row: Int) {
        // complete from todo section
        if section < 1 {
            print("complete \(todos[row])")
            dones.append(todos[row])
            todos.remove(at: row)
        }else{
        // reopen done item
            print("reopen \(dones[row])")
            todos.append(dones[row])
            dones.remove(at: row)
        }
        print(todos)
        print(dones)
        tableView.reloadData()
    }
    
    func deleteItem(section: Int, row: Int) {
        print("delete item \(section) \(row)")
        if section < 1 {
            todos.remove(at: row)
        }else{
            dones.remove(at: row)
        }
        saveList()
        refreshTableView()
    }
    
    func saveList() {
        print("save list \(listKey)")
        print(todos)
        print(dones)
        userdefaults.set(todos, forKey: "\(listKey)A")
        userdefaults.set(dones, forKey: "\(listKey)B")
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
    var highlightedCell = IndexPath(row: 0, section: 0)
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select row \(indexPath)")
        sectionBeingEdited = indexPath.section
        itemBeingEdited = indexPath.row
        if indexPath.section < 1 {
            // press on todo item
            if indexPath.row < todos.count {
                let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: 0)) as! TodoItemCell
                cell.setTextBold()
                print("select item \(todos[indexPath.row][0])")
            }else{
                // press on empty space, edit next cell
                let cell = tableView.cellForRow(at: IndexPath(row: todos.count, section: 0)) as! TodoItemCell
                //       print("enable row \(todos.count)")
                cell.textView.isUserInteractionEnabled = true
                cell.textView.becomeFirstResponder()
            }
        }
        

        
    }


    // MARK: - Table view initialization
    var cellHeight = CGFloat(44.0)
    var numOfTodoRows = 0
    var numOfDoneRows = 0
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 1 {
            return 10
        }
        return dones.count
    }
    

    func addEmptyRows() {
        var rows = 3
        let diff = UIScreen.main.bounds.height -  tableView.contentSize.height
        let cheight = cellHeight + 20.0 // top bottom padding
        if diff >  CGFloat(3.0) * cheight  {
            rows = Int(diff/cheight)
        }
        numOfTodoRows += rows
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = "todos"
        if section == 1 {
            title = "..."
        }
        return title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 //       print("\(indexPath.section) row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath) as! TodoItemCell
        cellHeight = cell.frame.height // ?? needed

        
        // --- TODOS -----
        if indexPath.section < 1 {
            if indexPath.row < todos.count {
                cell.textView.text = todos[indexPath.row][0] as! String
            }else{
                cell.textView.text = ""
            }
        }else{
        // --- DONES -----
            cell.textView.text = dones[indexPath.row][0] as! String
        }
        
        cell.textView.isUserInteractionEnabled = false

       
        cell.tableView = self
        cell.section = indexPath.section
        cell.row = indexPath.row
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
