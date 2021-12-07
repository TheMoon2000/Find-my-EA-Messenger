//
//  Comment Struct.swift
//  EA Center Messenger
//
//  Created by Jia Rui Shan on 1/7/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

import Cocoa

struct UserComment {
    var username = ""
//    var commentDate = NSDate() {
//        didSet {
//            let formatter = NSDateFormatter()
//            formatter.dateFormat = "y/MM/dd, h:mm a"
//            commentDateString = formatter.stringFromDate(commentDate)
//        }
//    }
    var commentDateString = ""
    var comment = ""
    var id = ""
    
    init(username: String, id: String, commentDate: String, comment: String) {
        self.username = username
        self.id = id
        self.commentDateString = commentDate
        self.comment = comment
    }
}

func ==(lhs: UserComment, rhs: UserComment) -> Bool {
    return lhs.username == rhs.username && lhs.id == rhs.id && lhs.commentDateString == rhs.commentDateString && lhs.comment == lhs.comment
}

extension UserComment: Equatable {}

