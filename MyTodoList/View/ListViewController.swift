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
        textView.sizeToFit()
        tableView.beginUpdates()
        tableView.endUpdates()
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("------- did begin editing \(textView.tag)")
        tableView.isScrollEnabled = false
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
                addAddButtonCell()
            }else{
                print("empty string, no add")
            }
            tableView.reloadData()
        }
        saveList()
        tableView.isScrollEnabled = true

    }
  
}

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var defaultText: UILabel!
    var todos = [[Any]]() // 0 - text , 1 - color
    var dones = [[Any]]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsBarHeight: NSLayoutConstraint!
    
    @IBOutlet weak var dateBar: UIView!
    @IBOutlet weak var itemBar: UIView!
    @IBOutlet weak var colorBtn1: UIButton!
    @IBOutlet weak var colorBtn2: UIButton!
    @IBOutlet weak var colorBtn3: UIButton!
    @IBOutlet weak var colorBtn4: UIButton!
    @IBOutlet weak var colorBtn5: UIButton!
    
    var currentListDate = Date()
    var list = "Daily"
    let dateFormatter = DateFormatter()
    let userdefaults = UserDefaults.standard
    var listKey = "list" // Daily 01.12.2018, Weekly 01.12.2018, Monthly 10.2018
    var itemBeingEdited = 0
    var sectionBeingEdited = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // TODO: disable textfields by default
  //      view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        // show date
        dateFormatter.dateFormat = "dd.MM.yyyy"
        loadDataForDate(listDate: Date())
 
    }
    
    var deleteDir = UITableViewRowAnimation.right
    var insertDir = UITableViewRowAnimation.left
    func loadDataForDate(listDate: Date) {
        print("load data for \(listDate)")
        currentListDate = listDate
        let title = dateFormatter.string(from: listDate)
        navigationItem.title = title
        listKey = "\(title)"
        
        // clear current list
        let todorows = todos.count
        print("current list todos count \(todorows)")
        todos.removeAll()
        var todopaths = [IndexPath]()
        for i in 0..<todorows {
            todopaths.append(IndexPath(row: i, section: 0))
        }
        print("delete current list todos")
        tableView.deleteRows(at: todopaths, with: deleteDir)
        
        
        let donerows = dones.count
        print("current list dones count \(donerows)")
        dones.removeAll()
        var donepaths = [IndexPath]()
        for i in 0..<donerows {
            donepaths.append(IndexPath(row: i, section: 1))
        }
        print("delete current list dones")
        if doneSectionExpanded {
            tableView.deleteRows(at: donepaths, with: deleteDir)
        }

        // load new list todos
        if let content = userdefaults.array(forKey: "\(listKey)A") {
            print("existing date for todos)")
            todos = content as! [[Any]]
            print(todos)
        }

        todopaths = [IndexPath]()
        for i in 0..<todos.count {
            todopaths.append(IndexPath(row: i, section: 0))
        }
        tableView.insertRows(at: todopaths, with: insertDir)

        // load new list dones
        if let content = userdefaults.array(forKey: "\(listKey)B") {
            print("existing data for dones")
            dones = content as! [[Any]]
            print(dones)
        }
        donepaths = [IndexPath]()
        for i in 0..<dones.count {
            donepaths.append(IndexPath(row: i, section: 1))
        }
        if doneSectionExpanded {
            tableView.insertRows(at: donepaths, with: insertDir)
        }

    }

    func addItem() {
        let cell = tableView.cellForRow(at: IndexPath(row: todos.count, section: 0)) as! TodoItemCell
        cell.hideAddButton()
        cell.setAsTodoCell()
        cell.textView.isUserInteractionEnabled = true
        cell.textView.becomeFirstResponder()
    }
    
    var swipeLocked = false
    func completeItem(section: Int, row: Int) {
        swipeLocked = true
        tableView.isScrollEnabled = false
        // complete from todo section
        if section < 1 {
            print("complete \(todos[row])")
            let item = todos[row]
            todos.remove(at: row)
            UIView.animate(withDuration: 0.3) {
                self.tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .right)
            }
            dones.append(item)
            if doneSectionExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.9) {
                    self.tableView.insertRows(at: [IndexPath(row: self.dones.count-1, section: 1)], with: .fade)
                    self.tableView.reloadData()
                    self.swipeLocked = false
                    self.tableView.isScrollEnabled = true
                }
            }
     
        }else{
        // reopen done item
                print("reopen row \(row) \(dones.count)")
                let item = dones[row]
                dones.remove(at: row)
            self.tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .right)
/*
            UIView.animate(withDuration: 0.3) {
            }*/
            
                todos.append(item)
            self.tableView.insertRows(at: [IndexPath(row: self.todos.count-1, section: 0)], with: .fade)
self.swipeLocked = false
            self.tableView.isScrollEnabled = true
            /*
            DispatchQueue.main.asyncAfter(deadline: .now()+0.9) {
                UIView.animate(withDuration: 0.3) {
                    self.tableView.reloadData()
             
                 //
                }
            }
            */
            
        }
        print(todos)
        print(dones)
        saveList()
    }
    
    func deleteItem(section: Int, row: Int) {
        print("delete item \(section) \(row)")
        swipeLocked = true
        if section < 1 {
            todos.remove(at: row)
        }else{
            dones.remove(at: row)
        }
        UIView.animate(withDuration: 0.3) {
            self.tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .left) }
        saveList()
        tableView.reloadData()
        swipeLocked = false
    }
    
    func saveList() {
        /*
        print("save list \(listKey)")
        print(todos)
        print(dones)
 */
        userdefaults.set(todos, forKey: "\(listKey)A")
        userdefaults.set(dones, forKey: "\(listKey)B")
    }
    
    @objc func keyboardWillShow(not: NSNotification) {
        print("keyboard up")
        
        if let size = (not.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            print(size)
            UIView.animate(withDuration: 0.33) {
                self.optionsBarHeight.constant = size.height + CGFloat(10)
                self.view.layoutIfNeeded()
            }

        }
    }
    
    @objc func keyboardWillHide() {
        print("keyboard down")
        UIView.animate(withDuration: 0.33) {
            self.optionsBarHeight.constant = 0
             self.view.layoutIfNeeded()
        }
        
    }

    func addAddButtonCell() {
        tableView.insertRows(at: [IndexPath(row: todos.count, section: 0)], with: .top)
    }
    
    @objc func doneSectionPressed() {
        if dones.count == 0 {
            print("no dones!")
            return
        }
        var paths = [IndexPath]()
        for count in 1 ... dones.count {
            print("count \(count)")
            paths.append(IndexPath(row: count-1, section: 1))
        }
        print(paths)
        doneSectionExpanded = !doneSectionExpanded
        if doneSectionExpanded {
            tableView.insertRows(at: paths, with: .automatic)

        }else{
            tableView.deleteRows(at: paths, with: .fade)
        }
   //     refreshTableView()
    }

    // MARK: - Bottom bars
    let colors = [UIColor(red: CGFloat(255.0/255.0), green: CGFloat(205.0/255.0), blue: CGFloat(195.0/255.0), alpha: 1.0),
                  UIColor(red: CGFloat(245.0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(210.0/255.0), alpha: 1.0),
                  UIColor(red: CGFloat(215.0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(215.0/255.0), alpha: 1.0),
                  UIColor(red: CGFloat(225.0/255.0), green: CGFloat(240.0/255.0), blue: CGFloat(255.0/255.0), alpha: 1.0),
                  UIColor.white]
    @IBAction func colorSelected(_ sender: UIButton) {
        print(sender.tag)
        let cell = tableView.cellForRow(at: highlightedCell) as! TodoItemCell
        cell.colorStripe.backgroundColor = colors[sender.tag-1]
    }
    
    @IBAction func todayPressed(_ sender: UIButton) {
        print("go to Today")
        let today = Date()
        print("list date \(currentListDate)")
        print("today \(today)")
        if dateFormatter.string(from: currentListDate) == dateFormatter.string(from: today) {
            print("equal")
            return
        }
        if currentListDate < today {
            deleteDir = .left
            insertDir = .right
        }else{
            deleteDir = .right
            insertDir = .left
        }
        loadDataForDate(listDate: Date())
  //      refreshTableView()
    }
    
    @IBAction func previousDayPressed(_ sender: UIButton) {
        deleteDir = .right
        insertDir = .left
      let previous = Calendar.current.date(byAdding: .day, value: -1, to: currentListDate)
        loadDataForDate(listDate: previous!)
   //     refreshTableView()
    }
    
    @IBAction func nextDayPressed(_ sender: UIButton) {
        deleteDir = .left
        insertDir = .right
        let next = Calendar.current.date(byAdding: .day, value: 1, to: currentListDate)
        print(next)
        loadDataForDate(listDate: next!)
    //   refreshTableView()
    }
    
    func showItemBar()
    {
        print("show item bar")
            dateBar.isHidden = true
            itemBar.isHidden = false
        
    }
    
    func hideItemBar() {
        print("hide item bar")
        itemBar.isHidden = true
        dateBar.isHidden = false
        dateBar.isUserInteractionEnabled = true
    }
    
    // MARK: - Table view
    func numberOfSections(in tableView: UITableView) -> Int {
       return 2
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < 1 {
            return nil
        }else{
            let button = UIButton(type: .system)
            if self.doneSectionExpanded {
                button.setTitle("completed...", for: .normal)
            }else{
                button.setTitle("...", for: .normal)
            }
            button.addTarget(self, action: #selector(doneSectionPressed), for: .touchUpInside)
            return button
        }
    }
    
    // --------   NUMBER OF ROWS IN SECTION ---------------
    var cellHeight = CGFloat(44.0)
    var numOfTodoRows = 0
    var numOfDoneRows = 0
    var doneSectionExpanded = true
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 1 {
            return todos.count + 1
        }else{
      //      return dones.count
            if doneSectionExpanded {
          //      print("num of rows in section 1 \(dones.count)")
                return dones.count
            }
            return 0
        }
    }

    // --------   DEQUEUE REUSABLE CELL ---------------
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  //      print("cellForRowAt \(indexPath.section) row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath) as! TodoItemCell
        cell.textView.isUserInteractionEnabled = false
        cell.tableView = self
        cell.section = indexPath.section
        cell.row = indexPath.row
        cell.textView.tag = indexPath.row
        cell.textView.delegate = self
                // --- TODOS -----
        if indexPath.section < 1 {
            if indexPath.row < todos.count {
                cell.hideAddButton()
                cell.textView.text = todos[indexPath.row][0] as! String + "  row \(cell.row)"
                cell.setAsTodoCell()
                cell.registerDoubleTap()
                cell.registerSwipes()
            }else{
          //      print("setAsAddItemCell")
                cell.setAsAddItemCell()
            }
        }else{
        // --- DONES -----
            cell.textView.text = dones[indexPath.row][0] as! String + "  row \(cell.row)"
            cell.setAsDoneCell()
            cell.registerSwipes()
        }
        return cell
    }
    
    
    // --------   SELECT ROW ---------------
    var highlightedCell = IndexPath(row: 0, section: 0)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select row \(indexPath)")
        sectionBeingEdited = indexPath.section
        itemBeingEdited = indexPath.row
        if indexPath.section < 1 {
            // press on todo item
            if indexPath.row < todos.count {
                view.endEditing(true)
                let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: 0)) as! TodoItemCell
                cell.setTextBold()
                print("select item \(todos[indexPath.row][0])")
                highlightedCell = indexPath
                showItemBar()
            }
   
        }
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
