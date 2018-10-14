//
//  TodoCell.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit



class TodoItemCell: UITableViewCell {


    var section = 0
    var row = 0
    var tableView : ListViewController?
    @IBOutlet weak var textView: UITextView!
    
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
        // Initialization code
          selectionStyle = .none
//        textView.returnKeyType = UIReturnKeyType.done
 //       contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped)))


    }
    
    @IBOutlet weak var addButton: UIButton!
    @IBAction func addItemPressed(_ sender: UIButton) {
        print("ADD Item")
        tableView?.addItem()
    }

    func setAsTodoCell() {
        textView.attributedText = NSAttributedString(string: textView.text, attributes: resetAttributes)
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
    
    func registerDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
        
    }
    
    @objc func swipedLeft () {
        print("swiped left \(section) \(row)")
        if tableView!.swipeLocked {
            print("locked")
            return
        }
        tableView?.deleteItem(section: section, row: row)
    }

    @objc func swipedRight () {
        print("swiped right \(section) \(row)")
        if tableView!.swipeLocked {
            print("locked")
            return
        }
        UIView.animate(withDuration: 0.3) {
                    self.textView.attributedText = NSAttributedString(string: self.textView.text, attributes: self.strikedAttribute) // TODO: animate
        }
        tableView?.completeItem(section: self.section, row: self.row)

    }
    
    @objc func doubleTapped () {
        print("dobule Tapped \(section) \(row)")
        textView.isUserInteractionEnabled = true
        textView.becomeFirstResponder()
    }
    
    var isBold = false
    func setTextBold() {
        print("set bold \(section) \(row)")
        if isBold {
            textView.text = textView.attributedText.string
        }else{
            textView.attributedText = NSAttributedString(string: textView.text, attributes: boldAttributes)
        }
        isBold = !isBold
    }

    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
