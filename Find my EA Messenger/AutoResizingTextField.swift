//
//  AutoResizingTextField.swift
//  Innovation Center
//
//  Created by Jia Rui Shan on 7/31/16.
//  Copyright © 2016 Tenic. All rights reserved.
//

import Cocoa

class AutoResizingTextField: NSTextField {

    override var intrinsicContentSize: NSSize {
        get {
            
            if (self.cell?.wraps != true) {
                return super.intrinsicContentSize
            }
            
            var frame = self.frame;
            let width = frame.size.width
            
            frame.size.height = CGFloat.greatestFiniteMagnitude;
            
            
            let height: CGFloat = (self.cell?.cellSize(forBounds: frame).height)! + 1
            
            return NSMakeSize(width, height)
        }
    }
    
    func refresh() {
        self.invalidateIntrinsicContentSize()
    }
    
}
