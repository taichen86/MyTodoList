//
//  TodoCell.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit
import AudioToolbox


class TodoItemCell: UITableViewCell {


    var indexPath = IndexPath(row: 0, section: 0)
    var section = 0
    var row = 0
    var tableView : ListViewController?
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var colorStripe: UIView!
    
    var strikedAttribute : [NSAttributedStringKey:Any] =
        [ .strikethroughStyle : NSUnderlineStyle.styleSingle.rawValue ,
          .font : UIFont.systemFont(ofSize: 20.0),
          .foregroundColor : UIColor.lightGray ]
    var boldAttributes : [NSAttributedStringKey:Any] =
        [ .font : UIFont.boldSystemFont(ofSize: 20.0) ]
    var resetAttributes : [NSAttributedStringKey:Any] =
        [ .font : UIFont.systemFont(ofSize: 20.0) ]
    
    var isDone = false
    override func awakeFromNib() {
        super.awakeFromNib()
          selectionStyle = .none

    }
    
    @IBOutlet weak var addButton: UIButton!
    @IBAction func addItemPressed(_ sender: UIButton) {
        AudioServicesPlaySystemSound(1104)
        addButton.isHidden = true
        textView.text = ""
        textView.isUserInteractionEnabled = true
        textView.becomeFirstResponder()
    }

    func removeColor() {
        colorStripe.backgroundColor = nil
    }
    func setColor(index: Int) {
        colorStripe.backgroundColor = tableView?.colors[index]
    }
    
    
    func setAsTodoCell() {
        addButton.isHidden = true
        textView.attributedText = NSAttributedString(string: textView.text, attributes: resetAttributes)
        textView.attributedText = NSAttributedString(string: "")
        textView.text = ""
    }

    func hideAddButton() {
        addButton.isHidden = true
    }
    
    var isStriked = false
    func setAsDoneCell()
    {
        textView.attributedText = NSAttributedString(string: textView.text, attributes: strikedAttribute)
        addButton.isHidden = true
    }
    
    func setAsAddItemCell() {
        textView.attributedText = NSAttributedString(string: textView.text, attributes: resetAttributes)
        textView.attributedText = NSAttributedString(string: "")
        textView.text = ""
        addButton.isHidden = false
    }
    
 
    func registerSwipes() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        swipeLeft.direction = .left
        contentView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeRight.direction = .right
        contentView.addGestureRecognizer(swipeRight)
    }
    

    var singleTap = UITapGestureRecognizer()
    var doubleTap = UITapGestureRecognizer()
    
    func registerTaps() {
        singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
        
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(singleTap)
        
    }
    
    func removeGestures() {
        if let gestures = contentView.gestureRecognizers {
            for gesture in gestures {
                contentView.removeGestureRecognizer(gesture)
            }
        }
    }
    
    func removeTapGestures() {
        contentView.removeGestureRecognizer(singleTap)
        contentView.removeGestureRecognizer(doubleTap)
    }
    
    @objc func swipedLeft () {
        if tableView!.swipeLocked {
            return
        }
        tableView?.deleteItem(ip: indexPath)
    }

    @objc func swipedRight () {
        if tableView!.swipeLocked {
            return
        }
        UIView.animate(withDuration: 0.3) {
                    self.textView.attributedText = NSAttributedString(string: self.textView.text, attributes: self.strikedAttribute) // TODO: animate
        }
        tableView?.completeItem(ip: indexPath)

    }
    
    @objc func singleTapped () {
        tableView?.selectRow(ip: indexPath)
    }
    
    @objc func doubleTapped () {
        tableView?.unhighlight()
        textView.isUserInteractionEnabled = true
        tableView?.activeIndexPath = indexPath
        textView.becomeFirstResponder()
    }

    func setBold() {
        textView.attributedText = NSAttributedString(string: textView.text, attributes: boldAttributes)
    }

    


}
