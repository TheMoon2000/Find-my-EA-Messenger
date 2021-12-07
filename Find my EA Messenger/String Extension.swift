//
//  String Extension.swift
//  Found my EA
//
//  Created by Jia Rui Shan on 1/7/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

import Foundation

let replaceScheme = [("__sq__", "'"), ("__dq__", "\""), ("__am__", "&"), ("__eq__", "="), ("__sc__", ";")]

extension String {
    func decodedString() -> String {
        var tmp = self
        for i in replaceScheme {
            tmp = tmp.replacingOccurrences(of: i.0, with: i.1)
        }
        return tmp
    }
    
    func encodedString() -> String {
        var tmp = self
        for i in replaceScheme {
            tmp = tmp.replacingOccurrences(of: i.1, with: i.0)
        }
        return tmp
    }
}
