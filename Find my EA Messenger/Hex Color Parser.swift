//
//  Hex Color Parser.swift
//  Find my EA Messenger
//
//  Created by Jia Rui Shan on 4/2/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

import Cocoa

func getColorFromString(_ webColorString : String) -> NSColor?
{
    var result : NSColor? = nil
    var colorCode : UInt32 = 0
    var redByte, greenByte, blueByte : UInt8
    
    // these two lines are for web color strings that start with a #
    // -- as in #ABCDEF; remove if you don't have # in the string
    let index1 = webColorString.characters.index(webColorString.endIndex, offsetBy: -6)
    let substring1 = webColorString.substring(from: index1)
    
    let scanner = Scanner(string: substring1)
    let success = scanner.scanHexInt32(&colorCode)
    
    if success == true {
        redByte = UInt8.init(truncatingBitPattern: (colorCode >> 16))
        greenByte = UInt8.init(truncatingBitPattern: (colorCode >> 8))
        blueByte = UInt8.init(truncatingBitPattern: colorCode) // masks off high bits
        
        result = NSColor(calibratedRed: CGFloat(redByte) / 0xff, green: CGFloat(greenByte) / 0xff, blue: CGFloat(blueByte) / 0xff, alpha: 1.0)
    }
    return result
}
