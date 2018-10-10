//
//  TodoCell.swift
//  MyTodoList
//
//  Created by tai chen on 08/10/2018.
//  Copyright © 2018 TPBSoftware. All rights reserved.
//

import UIKit



class TodoItemCell: UITableViewCell {


    var tableView : ListViewController?
    @IBOutlet weak var textView: UITextView!
    
    var strikedAttribute : [NSAttributedStringKey:Any] =
        [ .strikethroughStyle : NSUnderlineStyle.styleSingle.rawValue ,
          .font : UIFont.systemFont(ofSize: 20.0),
          .foregroundColor : UIColor.lightGray ]
    
    var isDone = false
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        
        // Initialization code
          selectionStyle = .none
//        textView.returnKeyType = UIReturnKeyType.done
 //       contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped)))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        swipeLeft.direction = .left
        textView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeRight.direction = .right
        textView.addGestureRecognizer(swipeRight)
        
    }
    
    @objc func swipedLeft () {
        print("swiped left")
        tableView?.deleteItem(index: textView.tag)
    }

    @objc func swipedRight () {
        print("swiped right")
        if isDone {
            textView.text = textView.attributedText.string
        }else{
            textView.attributedText = NSAttributedString(string: textView.text, attributes: strikedAttribute)
        }
        isDone = !isDone
    }
        
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
