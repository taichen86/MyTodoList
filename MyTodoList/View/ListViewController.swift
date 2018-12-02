//
//  ListViewController.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit
import CVCalendar
import UserNotifications

enum CMode {
    case date
    case move
    case alarm
    case none
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
   //     tableView.isScrollEnabled = false
        print("did begin editing")
        activeTextView = textView
    }
 
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.isUserInteractionEnabled = false
        textView.text = textView.text.trimmingCharacters(in: .whitespaces)
        if textView.tag < todos.count {
            todos[textView.tag][0] = textView.text!
            if textView.text.isEmpty {
                deleteItem(ip: (textView.superview?.superview as! TodoItemCell).indexPath)
            }
        }else{
            var todo : [Any] = [""]
            if !textView.text.isEmpty {
                todo[0] = textView.text!
                todos.append(todo)
                addAddButtonCell()
            }
        }
        saveList()
        tableView.isScrollEnabled = true
        tableView.reloadData()

    }
  
}



class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, IAPDelegate {
    var activeTextView : UITextView?

    var todos = [[Any]]() // 0 - text , 1 - color
    var dones = [[Any]]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableviewBottomConstraint: NSLayoutConstraint!
    
    var currentListDate = Date()
    let dateFormatter2 = DateFormatter()
    let dayFormatter = DateFormatter()
    let dateFormatter = DateFormatter()
    let userdefaults = UserDefaults.standard
    var listKey = "list" // Daily 01.12.2018, Weekly 01.12.2018, Monthly 10.2018
    

    
    var bottomViewTimer = Timer()
    var bottomViewCounter = 0
    
    var cmode = CMode.date
    
    let importNotificationName = Notification.Name(rawValue: "importcompletednotification")
    let importErrorNotificationName = Notification.Name(rawValue: "importerrornotification")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createObservers()
        
        IAP.instance.iapDelegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = colors[4]
       
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        bottomViewHeight.constant = 0.07 * view.bounds.height
        
        // show date
        dateFormatter.dateFormat = "dd.MM.yyyy"
        calendarTitleFormatter.dateFormat = "MMMM yyyy"
        dayFormatter.dateFormat = "EEEE"
        dateFormatter2.dateFormat = "d MMM yyyy"
        
        
        loadDataForDate(listDate: Date())
        
        if userdefaults.object(forKey: "firstTime") == nil {
            todos.append(["-> swipe right to complete",1])
            todos.append(["<- swipe left to delete ",2])
            todos.append(["double click to edit",3])
            todos.append(["press + to add",0])
            userdefaults.set(false, forKey: "firstTime")
        }
    
        bottomViewCounter = 6
        bottomViewTimer =  Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(idleTimer), userInfo: nil, repeats: true)
       
        calendarView.delegate = self
        calendarMenu.delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { (didAllow, error) in
            
        }
        
        
    }
    var spinner = UIActivityIndicatorView()
    
    @objc func idleTimer() {
        if !calendarView.isHidden {
            return
        }
        if bottomViewCounter > 0 {
            bottomViewCounter -= 1
            return
        }
        if bottomViewHeight.constant > 0 {
            hideBottomView()
        }
    }
    
    var deleteDir = UITableViewRowAnimation.right
    var insertDir = UITableViewRowAnimation.left
    func loadDataForDate(listDate: Date) {
        if userdefaults.bool(forKey: "upgrade") == false {
            if !isSameDate(date1: listDate, date2: Date()) {
                upgradeText = ListViewController.UNLOCK_DATE
                checkPremiumAccess()
                return
            }
        }

        currentListDate = listDate
        let key = dateFormatter.string(from: currentListDate)
        listKey = "\(key)"
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "EEEE MMM d, yyyy"
        navigationItem.title = titleFormatter.string(from: listDate)
        
        highlightedCell = nil
        
        // clear current list
        let todorows = todos.count
        todos.removeAll()
        var todopaths = [IndexPath]()
        for i in 0..<todorows {
            todopaths.append(IndexPath(row: i, section: 0))
        }
        tableView.deleteRows(at: todopaths, with: deleteDir)
        
        
        let donerows = dones.count
        dones.removeAll()
        var donepaths = [IndexPath]()
        for i in 0..<donerows {
            donepaths.append(IndexPath(row: i, section: 1))
        }
        if doneSectionExpanded {
            tableView.deleteRows(at: donepaths, with: deleteDir)
        }

        // load new list todos
        if let content = userdefaults.array(forKey: "\(listKey)A") {
            todos = content as! [[Any]]
        }

        todopaths = [IndexPath]()
        for i in 0..<todos.count {
            todopaths.append(IndexPath(row: i, section: 0))
        }
        tableView.insertRows(at: todopaths, with: insertDir)

        // load new list dones
        if let content = userdefaults.array(forKey: "\(listKey)B") {
            dones = content as! [[Any]]
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
        if dateFormatter.string(from: date1) != dateFormatter.string(from: date2) {
            return false
        }
        return true
    }
    
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var alarmButton: UIButton!
    
    static let UNLOCK_DATE = "Access to lists for other days is a premium feature. Upgrade?"
    static let UNLOCK_MOVE = "Moving tasks to other days is a premium feature. Upgrade?"
    static let UNLOCK_ALARM = "Setting alarm notification for tasks is a premium feature. Upgrade?"
    var upgradeText = UNLOCK_DATE
    
    func checkPremiumAccess() {
        if userdefaults.bool(forKey: "upgrade") == false {
            let alert = UIAlertController(title: "unlock", message: upgradeText, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "later", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: { (action) in
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
  
            }
     
        }else{
        // reopen done item
                let item = dones[ip.row]
                dones.remove(at: ip.row)
            self.tableView.deleteRows(at: [ip], with: .right)

                todos.append(item)
            self.tableView.insertRows(at: [IndexPath(row: self.todos.count-1, section: 0)], with: .fade)
            self.swipeLocked = false
            self.tableView.isScrollEnabled = true

            
        }

        saveList()
    }
    
    func deleteItem(ip: IndexPath) {
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
        /*
        if let size = (not.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.bottomViewHeight.constant = size.height + CGFloat(10)
            UIView.animate(withDuration: 0.33) {
                self.view.layoutIfNeeded()
            }
        }*/
    }
    
    var activeIndexPath = IndexPath(row: 0, section: 0)
    @objc func keyboardDidShow(not: NSNotification) {
         if let size = (not.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            guard let textview = activeTextView else { return }
            let point = textview.convert(CGPoint(x: textview.frame.width, y: textview.frame.height), to: view)
            print(point)
            let offset = view.frame.height - size.height - point.y
            print("offset \(offset)")
            print("offest \(tableView.contentOffset.y)")
            if offset < 0 {
                print("scroll up!")
      //          tableView.scrollToRow(at: activeIndexPath, at: .top, animated: true)
                tableviewBottomConstraint.constant = size.height
                let scrollBy = offset * -1.0 + tableView.contentOffset.y + 20
                print("scroll by \(scrollBy)")
                tableView.setContentOffset(CGPoint(x: 0, y: scrollBy), animated: true)
            }
         }
    }
    
    @objc func keyboardWillHide() {
        self.bottomViewHeight.constant = 0
        UIView.animate(withDuration: 0.33) {
            self.tableviewBottomConstraint.constant = 0
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
        if dones.count == 0 {
            doneSectionExpanded = !doneSectionExpanded
            tableView.reloadData()
            return
        }
        var paths = [IndexPath]()
        for count in 1 ... dones.count {
            paths.append(IndexPath(row: count-1, section: 1))
        }
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
        saveList()
    }
    
    @IBAction func alarmPressed(_ sender: UIButton) {
        if userdefaults.bool(forKey: "upgrade") {
            cmode = .alarm
            toggleCalendar()
        }else{
            upgradeText = ListViewController.UNLOCK_ALARM
            checkPremiumAccess()
        }
    }
    
    @IBAction func moveItemPressed(_ sender: UIButton) {
        if userdefaults.bool(forKey: "upgrade") {
            cmode = .move
            toggleCalendar()
        }else{
            upgradeText = ListViewController.UNLOCK_MOVE
            checkPremiumAccess()
        }

    }
    
    @IBOutlet weak var calendarTitle: UILabel!
    @IBOutlet weak var calendarMenu: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var calendarButton: UIButton!
    @IBAction func calendarPressed(_ sender: UIButton) {
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
            // reset to today's date WHY??? reset calendar only - not list
            cmode = .none
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
        // TODO: distinguish between slide and selected
        if let date = date.convertedDate() {
            switch cmode {
            case .date:
                loadDataForDate(listDate: date)
            case .move:
                moveItemTo(targetDate: date)
            case .alarm:
                setAlarmFor(targetDate: date)
            default:
                break
            }
  
        }
    }
    
    func didShowNextMonthView(_ date: Date) {
        calendarTitle.text = "\n" + calendarTitleFormatter.string(from: date)
    }
    
    func didShowPreviousMonthView(_ date: Date) {
        calendarTitle.text = "\n" + calendarTitleFormatter.string(from: date)
    }
    
    func setAlarmFor( targetDate: Date ){
        guard let item = highlightedCell else { return }
        
        var dc = DateComponents()
        dc = Calendar.current.dateComponents([.day,.month,.year], from: targetDate)
        dc.hour = 7
        dc.minute = 0
        
        let not = UNMutableNotificationContent()
        not.title = "reminder"
        not.body = todos[item.row][0] as! String
        not.badge = 1
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder", content: not, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
 
        hideBottomView()
        
        let day = NSCalendar.current.date(from: dc)
        
        let alert = UIAlertController(title: "notification", message: "reminder for this task set for \n \(dateFormatter2.string(from: day!))", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    func moveItemTo( targetDate : Date ){
        if isSameDate(date1: currentListDate, date2: targetDate) {
            return
        }
        let listkey = dateFormatter.string(from: targetDate) + "A"
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

            deleteItem(ip: item)
        }
        
    }
    
    @IBAction func todayPressed(_ sender: UIButton) {
        hideCalendar()
        bottomViewCounter = 10
        let today = Date()
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
    }
    
    @IBAction func previousDayPressed(_ sender: UIButton) {
        hideCalendar()
        bottomViewCounter = 10
        deleteDir = .right
        insertDir = .left
      let previous = Calendar.current.date(byAdding: .day, value: -1, to: currentListDate)
        loadDataForDate(listDate: previous!)
    }
    
    func hideCalendar() {
        if !calendarView.isHidden {
            cmode = .none
            toggleCalendar()
        }
    }
    
    @IBAction func nextDayPressed(_ sender: UIButton) {
        hideCalendar()
        bottomViewCounter = 10
        deleteDir = .left
        insertDir = .right
        let next = Calendar.current.date(byAdding: .day, value: 1, to: currentListDate)
        loadDataForDate(listDate: next!)
    }
    
    func showItemBar()
    {
        dateBar.isHidden = true
        setPremiumButtons(stat: userdefaults.bool(forKey: "upgrade"))
        itemBar.isHidden = false
    }
    
    func setPremiumButtons(stat: Bool) {
        alarmButton.alpha = 0.6
        moveButton.alpha = 0.6
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
        showDateBar()
 
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

            if doneSectionExpanded {
                button.setTitle("completed...",  for: .normal)
            }else{
                button.setTitle("...", for: .normal)
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
    
    var cellHeights = [Int:CGFloat]()
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //    print("cellForRowAt \(indexPath.section) row \(indexPath.row)")
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
            if dones[indexPath.row].count > 1 {
                cell.setColor(index: dones[indexPath.row][1] as! Int)
            }
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
   //     print("estimated height: \(cellHeights[indexPath.row])")
        return cellHeights[indexPath.row] ?? 100.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath.row] = cell.frame.size.height
 //       print("cell height \(cell.frame.height)")
//
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

        tableView.reloadRows(at: [ip], with: .none)
    }
    
    func restoreSuccessAlert() {
        let alert = UIAlertController(title: "success", message: "purchase restored", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: notification observers
    
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: importNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showImportErrorAlert), name: importErrorNotificationName, object: nil)
    }
    
    @objc func refreshView(){
        let alert = UIAlertController(title: "success", message: "Backup data imported!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        loadDataForDate(listDate: Date())
    }
    
    @objc func showImportErrorAlert(){
        let alert = UIAlertController(title: "error", message: "Your data could not be imported. Please contact the developer.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}


extension ListViewController : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // display notification while app is in foreground
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

