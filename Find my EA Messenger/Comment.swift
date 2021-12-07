//
//  Comment.swift
//  Find my EA Messenger
//
//  Created by Jia Rui Shan on 1/6/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

import Cocoa

class Comment: NSTableCellView {
    
    var timestamp = ""
    var senderID = ""
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var userComment: NSTextField!
    var date = "" {
        didSet {
            let formatter = DateFormatter()
            formatter.dateFormat = "y/MM/dd"
            var givenDate = date.components(separatedBy: ", ")
            if givenDate[0] == formatter.string(from: Date()) {
                commentDate.stringValue = "Today at " + givenDate[1]
            } else if givenDate[0] == formatter.string(from: Date().addingTimeInterval(-86400)) {
                commentDate.stringValue = "Yesterday at " + givenDate[1]
            } else {
                commentDate.stringValue = date
            }
        }
    }
    @IBOutlet weak var commentDate: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        
    }
    
    override func awakeFromNib() {
        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor(white: 1, alpha: 0.5).cgColor
    }
    
}
