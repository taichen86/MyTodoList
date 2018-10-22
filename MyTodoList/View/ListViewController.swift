//
//  ListViewController.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit
import CVCalendar

enum CMode {
    case date
    case move
}

extension ListViewController: UITextViewDelegate, CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
    func presentationMode() -> CalendarMode {
        return .monthView
    }
    
    func firstWeekday() -> Weekday {
        return .monday
    }
    
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
   //     print("------- did begin editing \(textView.tag)")
        tableView.isScrollEnabled = false
    }
 
    func textViewDidEndEditing(_ textView: UITextView) {
  //    print("did end editing \(textView.tag)")
        textView.isUserInteractionEnabled = false
        textView.text = textView.text.trimmingCharacters(in: .whitespaces)
        if textView.tag < todos.count {
//       print("edit existing \(textView.tag)")
            todos[textView.tag][0] = textView.text!
            if textView.text.isEmpty {
                deleteItem(ip: (textView.superview?.superview as! TodoItemCell).indexPath)
            }
        }else{
            var todo : [Any] = [""]
            if !textView.text.isEmpty {
                todo[0] = textView.text!
                todos.append(todo)
     //          print("add new item \(textView.tag)")
                addAddButtonCell()
            }
        }
        saveList()
        tableView.isScrollEnabled = true
        tableView.reloadData()

    }
  
}



class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, IAPDelegate {

    var todos = [[Any]]() // 0 - text , 1 - color
    var dones = [[Any]]()
    
    @IBOutlet weak var tableView: UITableView!

    var currentListDate = Date()
    let dayFormatter = DateFormatter()
    let dateFormatter = DateFormatter()
    let userdefaults = UserDefaults.standard
    var listKey = "list" // Daily 01.12.2018, Weekly 01.12.2018, Monthly 10.2018
    

    
    var bottomViewTimer = Timer()
    var bottomViewCounter = 0
    
    var cmode = CMode.date
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IAP.instance.iapDelegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = colors[4]
       
        // TODO: disable textfields by default
  //      view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        bottomViewHeight.constant = 0.07 * view.bounds.height
 //       print("bottom view height \(bottomViewHeight.constant)")
        // show date
        dateFormatter.dateFormat = "dd.MM.yyyy"
        calendarTitleFormatter.dateFormat = "MMMM yyyy"
        dayFormatter.dateFormat = "EEEE"
        
        
        loadDataForDate(listDate: Date())
 
        // first time user
   //     userdefaults.removeObject(forKey: "firstTime")
 //       print("lets see user defaults stuff")
  //      print( userdefaults.object(forKey: "firstTime") )
        
        if userdefaults.object(forKey: "firstTime") == nil {
      //      print("first time using app")
            todos.append(["-> swipe right to complete",1])
            todos.append(["<- swipe left to delete ",2])
            todos.append(["double click to edit",3])
            todos.append(["press + to add",0])
            userdefaults.set(false, forKey: "firstTime")
   //         print(userdefaults.object(forKey: "firstTime"))
        }
    
        bottomViewCounter = 6
        bottomViewTimer =  Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(idleTimer), userInfo: nil, repeats: true)
       
        calendarView.delegate = self
        calendarMenu.delegate = self
        
    }
    var spinner = UIActivityIndicatorView()
    
    @objc func idleTimer() {
        if !calendarView.isHidden {
            return
        }
        if bottomViewCounter > 0 {
            bottomViewCounter -= 1
   //         print("bottom view counter \(bottomViewCounter)")
            return
        }
        if bottomViewHeight.constant > 0 {
            hideBottomView()
        }
    }
    
    var deleteDir = UITableViewRowAnimation.right
    var insertDir = UITableViewRowAnimation.left
    func loadDataForDate(listDate: Date) {
        if !isSameDate(date1: listDate, date2: Date())
            && !userdefaults.bool(forKey: "upgrade") {
            checkPremiumAccess()
            return
        }

  //    print("load data for \(listDate)")
        currentListDate = listDate
        let key = dateFormatter.string(from: currentListDate)
        listKey = "\(key)"
  //      print("list key \(listKey)")
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "EEEE MMM d, yyyy"
        navigationItem.title = titleFormatter.string(from: listDate)
        
        highlightedCell = nil
        
        // clear current list
        let todorows = todos.count
 //       print("current list todos count \(todorows)")
        todos.removeAll()
        var todopaths = [IndexPath]()
        for i in 0..<todorows {
            todopaths.append(IndexPath(row: i, section: 0))
        }
  //      print("delete current list todos")
        tableView.deleteRows(at: todopaths, with: deleteDir)
        
        
        let donerows = dones.count
  //      print("current list dones count \(donerows)")
        dones.removeAll()
        var donepaths = [IndexPath]()
        for i in 0..<donerows {
            donepaths.append(IndexPath(row: i, section: 1))
        }
 //       print("delete current list dones")
        if doneSectionExpanded {
            tableView.deleteRows(at: donepaths, with: deleteDir)
        }

        // load new list todos
        if let content = userdefaults.array(forKey: "\(listKey)A") {
    //        print("existing date for todos)")
            todos = content as! [[Any]]
     //       print(todos)
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
    
    func isSameDate(date1: Date, date2: Date) -> Bool {
        print("compare \(dateFormatter.string(from: date1)) and \(dateFormatter.string(from: date2))")
        if dateFormatter.string(from: date1) != dateFormatter.string(from: date2) {
            return false
        }
        return true
    }
    
    func checkPremiumAccess() {

        let purchased = userdefaults.bool(forKey: "upgrade")
  //      print("check premium access: \(purchased)")
        if purchased == false {
            let alert = UIAlertController(title: "unlock", message: "upgrade for full access to past and future lists?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "later", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: { (action) in
          //      print("upgrade...")
                IAP.instance.purchase()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
 
    

    var swipeLocked = false
    func completeItem(ip: IndexPath ) {
        if itemBar.isHidden == false {
            hideBottomView()
        }
        
        swipeLocked = true
        tableView.isScrollEnabled = false
        // complete from todo section
        if ip.section < 1 {
     //       print("complete \(todos[ip.row])")
            if let bold = highlightedCell {
                if bold == ip {
                    highlightedCell = nil
                }
            }
            let item = todos[ip.row]
            todos.remove(at: ip.row)
            UIView.animate(withDuration: 0.3) {
                self.tableView.deleteRows(at: [ip], with: .right)
            }
            dones.append(item)
            if doneSectionExpanded {
                tableView.reloadData()
                swipeLocked = false
                self.tableView.isScrollEnabled = true
                /*
                let donePath = IndexPath(row: self.dones.count-1, section: 1)
                if dones.count > 1 && cellVisible(path: <#T##IndexPath#>) {
                    print("done cell visible animate")
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.9) {
                        self.tableView.insertRows(at: [donePath], with: .fade)
                        self.tableView.reloadData()
                        self.swipeLocked = false
                        self.tableView.isScrollEnabled = true
                }
                }else{
                    print("done cell not visible")
                 
                }*/
            }
     
        }else{
        // reopen done item
       //         print("reopen row \(ip.row) \(dones.count)")
                let item = dones[ip.row]
                dones.remove(at: ip.row)
            self.tableView.deleteRows(at: [ip], with: .right)
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
  //      print(todos)
  //      print(dones)
        saveList()
    }
    
    func deleteItem(ip: IndexPath) {
 //       print("delete item \(ip.section) \(ip.row)")
        if itemBar.isHidden == false {
            hideBottomView()
        }
        
        swipeLocked = true
        tableView.isScrollEnabled = false
        if ip.section < 1 {
            todos.remove(at: ip.row)
        }else{
            dones.remove(at: ip.row)
        }
        UIView.animate(withDuration: 0.3) {
            self.tableView.deleteRows(at: [ip], with: .left) }
        saveList()
        tableView.reloadData()
        swipeLocked = false
        tableView.isScrollEnabled = true
    }
    
    func saveList() {
        userdefaults.set(todos, forKey: "\(listKey)A")
        userdefaults.set(dones, forKey: "\(listKey)B")
    }
    
    @objc func keyboardWillShow(not: NSNotification) {
        if let size = (not.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
     //       print(size)
            self.bottomViewHeight.constant = size.height + CGFloat(10)
            UIView.animate(withDuration: 0.33) {
                self.view.layoutIfNeeded()
            }

        }
    }
    
    @objc func keyboardWillHide() {
        self.bottomViewHeight.constant = 0
        UIView.animate(withDuration: 0.33) {
             self.view.layoutIfNeeded()
        }
    }
    
    func unhighlight() {
        if highlightedCell != nil {
            selectRow(ip: highlightedCell!)
            highlightedCell = nil
            tableView.reloadData()
        }
    }

    func addAddButtonCell() {
        tableView.insertRows(at: [IndexPath(row: todos.count, section: 0)], with: .top)
    }
    
    @objc func doneSectionPressed() {
   //     print("done section pressed \(dones.count)")
        if dones.count == 0 {
      //      print("no dones!")
            doneSectionExpanded = !doneSectionExpanded
            tableView.reloadData()
            return
        }
        var paths = [IndexPath]()
        for count in 1 ... dones.count {
            paths.append(IndexPath(row: count-1, section: 1))
        }
   //     print(paths)
        doneSectionExpanded = !doneSectionExpanded
        if doneSectionExpanded {
            tableView.insertRows(at: paths, with: .automatic)
        }else{
            tableView.deleteRows(at: paths, with: .fade)
        }
        tableView.reloadData()
    }

    // -------- BOTTOM BAR ---------------

    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dateBar: UIView!
    @IBOutlet weak var itemBar: UIView!
    @IBOutlet weak var colorBtn1: UIButton!
    @IBOutlet weak var colorBtn2: UIButton!
    @IBOutlet weak var colorBtn3: UIButton!
    @IBOutlet weak var colorBtn4: UIButton!
    @IBOutlet weak var colorBtn5: UIButton!
    
    let colors = [
                  UIColor(red: CGFloat(255.0/255.0), green: CGFloat(140.0/255.0), blue: CGFloat(125.0/255.0), alpha: 1.0),
                  UIColor(red: CGFloat(245.0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(165.0/255.0), alpha: 1.0),
                  UIColor(red: CGFloat(175.0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(200.0/255.0), alpha: 1.0),
                  UIColor(red: CGFloat(165.0/255.0), green: CGFloat(210.0/255.0), blue: CGFloat(255.0/255.0), alpha: 1.0),
                  UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 240.0/255.0, alpha: 1.0)]
    @IBAction func colorSelected(_ sender: UIButton) {
  //      print(sender.tag)
        bottomViewCounter = 10
        guard let selected = highlightedCell else {
            return
        }
        
        let cell = tableView.cellForRow(at: selected) as! TodoItemCell
        cell.colorStripe.backgroundColor = colors[sender.tag-1]
        
        if todos[selected.row].count == 1 {
            todos[selected.row].append(sender.tag-1)
        }else{
            todos[selected.row][1] = sender.tag-1
        }
  //      print(todos)
        saveList()
    }
    
    
    @IBAction func moveItemPressed(_ sender: UIButton) {
        print("move item pressed")
        cmode = .move
        // show calendar
        toggleCalendar()
    }
    
    @IBOutlet weak var calendarTitle: UILabel!
    @IBOutlet weak var calendarMenu: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var calendarButton: UIButton!
    @IBAction func calendarPressed(_ sender: UIButton) {
        print( "calendar pressed" )
        cmode = .date
        toggleCalendar()
    }
    
    func toggleCalendar() {
        if calendarView.isHidden {
            calendarTitle.text = "\n" + calendarTitleFormatter.string(from: Date())
            calendarMenu.commitMenuViewUpdate()
            calendarView.commitCalendarViewUpdate()
            showCalendar(false)
        }else{
            // reset to today's date
            calendarView.toggleCurrentDayView()
            showCalendar(true)
        }
    }

    func showCalendar( _ stat: Bool){
        calendarView.isHidden = stat
        calendarMenu.isHidden = stat
        calendarTitle.isHidden = stat
    }
    
    
    let calendarTitleFormatter  = DateFormatter()
    func presentedDateUpdated(_ date: CVDate) {
        if let date = date.convertedDate() {
            print(date)
            calendarTitle.text = "\n" + calendarTitleFormatter.string(from: date)
            if cmode == .date {
                loadDataForDate(listDate: date)
            }else{
                moveItemTo(targetDate: date)
            }
        }
    }
    
    func moveItemTo( targetDate : Date ){
        print("move item to \(targetDate)")
        let listkey = dateFormatter.string(from: targetDate) + "A"
        print("target key \(listkey)")
        if let item = highlightedCell {
            if userdefaults.object(forKey: listkey) == nil {
                var content = [[Any]]()
                content.append(todos[item.row])
                userdefaults.set(content, forKey: listkey)
            }else{
                var content = userdefaults.array(forKey: listkey)!
                content.append(todos[item.row])
                userdefaults.set(content, forKey: listkey)
            }
            print("moved to result")
            print(userdefaults.array(forKey: listkey))
            deleteItem(ip: item)
        }
        
    }
    
    @IBAction func todayPressed(_ sender: UIButton) {
        bottomViewCounter = 10
  //      print("go to Today")
        let today = Date()
  //      print("list date \(currentListDate)")
  //      print("today \(today)")
        if dateFormatter.string(from: currentListDate) == dateFormatter.string(from: today) {
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
        bottomViewCounter = 10

        deleteDir = .right
        insertDir = .left
      let previous = Calendar.current.date(byAdding: .day, value: -1, to: currentListDate)
        loadDataForDate(listDate: previous!)
   //     refreshTableView()
    }
    
    @IBAction func nextDayPressed(_ sender: UIButton) {
        bottomViewCounter = 10
        deleteDir = .left
        insertDir = .right
        let next = Calendar.current.date(byAdding: .day, value: 1, to: currentListDate)
 //       print(next)
        loadDataForDate(listDate: next!)
    //   refreshTableView()
    }
    
    func showItemBar()
    {
        dateBar.isHidden = true
        itemBar.isHidden = false
    }
    
    func hideItemBar() {
        itemBar.isHidden = true
        dateBar.isHidden = false
    }
    
    func showDateBar() {
        itemBar.isHidden = true
        dateBar.isHidden = false
    }
    
    func hideBottomView() {
       unhighlight()
        if calendarView.isHidden == false {
            toggleCalendar()
        }
        bottomViewHeight.constant = 0
        /*
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }*/
        showDateBar()
        /*
        DispatchQueue.main.asyncAfter(deadline: .now()+0.23) {
            self.showDateBar()
        }*/
    }
    
    func showBottomView() {
        bottomViewCounter = 10
        bottomViewHeight.constant = 0.07 * view.bounds.height
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !itemBar.isHidden {
            hideBottomView()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y <= 0 {
            showBottomView()
        }
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
            button.setTitleColor(UIColor.darkGray, for: .normal)
            button.backgroundColor = colors[4]
/*
            if dones.count < 1 {
                button.setTitle("...", for: .normal)
                return button
            }*/
    //        print("expanded \(doneSectionExpanded)")
            if doneSectionExpanded {
                button.setTitle("completed ↑",  for: .normal)
            }else{
                button.setTitle("... ↓", for: .normal)
            }
            button.addTarget(self, action: #selector(doneSectionPressed), for: .touchUpInside)
            return button
        }
    }
    
    // --------   NUMBER OF ROWS IN SECTION ---------------
    var doneSectionExpanded = true
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 1 {
            return todos.count + 1
        }else{
            if doneSectionExpanded {
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
        cell.indexPath = indexPath
        cell.textView.tag = indexPath.row
        cell.textView.delegate = self
        cell.removeColor()
        
                // --- TODOS -----
        if indexPath.section < 1 {
            if indexPath.row < todos.count {
          //      cell.hideAddButton()
                cell.setAsTodoCell()

                cell.textView.text = todos[indexPath.row][0] as! String /*+ "  row \(cell.indexPath.row)"*/
                if todos[indexPath.row].count > 1 {
                    cell.setColor(index: todos[indexPath.row][1] as! Int)
                }
                
                if let bold = highlightedCell {
                    if indexPath == bold {
                        cell.setBold()
                    }
                }
                
                cell.registerTaps()
                cell.registerSwipes()
                
            }else{
                cell.setAsAddItemCell()
            }
        }else{
        // --- DONES -----
            cell.textView.text = dones[indexPath.row][0] as! String /* + "  row \(cell.indexPath.row)" */
            cell.setAsDoneCell()
            cell.registerSwipes()
            // TODO: deregister taps
        //    cell.removeTapGestures()
            if dones[indexPath.row].count > 1 {
                cell.setColor(index: dones[indexPath.row][1] as! Int)
            }
        }
        return cell
    }
    
    
    // --------   SELECT ROW ---------------
    var highlightedCell : IndexPath?
    func selectRow(ip: IndexPath) {
        if ip.section > 0 { return }
        if ip.row >= todos.count { return }
        // press on todo item
        view.endEditing(true)
        if let selected = highlightedCell {
            if ip != selected {
                highlightedCell = ip
                bottomViewCounter = 5
                showItemBar()
                showBottomView()
            }else{
                highlightedCell = nil
                bottomViewCounter = 0
                hideBottomView()
            }
        }else{
            highlightedCell = ip
            bottomViewCounter = 5
            showItemBar()
            showBottomView()
        }
        print("reload section 0")
        tableView.reloadSections([0], with: .none)
    }
    
    func restoreSuccessAlert() {
        let alert = UIAlertController(title: "success", message: "purchase restored", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
}

