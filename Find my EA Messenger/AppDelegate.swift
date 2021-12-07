//
//  AppDelegate.swift
//  EA Center Messenger
//
//  Created by Jia Rui Shan on 12/21/16.
//  Copyright 2016 Jerry Shan. All rights reserved.
//

import Cocoa

let globalDelay = 30

let displayDateFormat = "h:mm a, MMM. d, y"
let mediumDateFormat = "y/MM/dd H:mm:ss"
let longDateFormat = "y/MM/dd HH:mm:ss:SSS"
let commentDateShortFormat = "y/MM/dd, h:mm a"

let serverAddress = "http://47.52.6.204/"

let displayFormatter = DateFormatter()
let formatter = DateFormatter()
let commentDateFormatter = DateFormatter()

func isTeacher(_ id: String) -> Bool { // A function that determines whether a given ID is of a teacher or student
    
    if ["SSEA", "99999999"].contains(id) {return true}
    if id.characters.count < 8 {return false}
    
    if id.characters.count == 10 {return false}
    
    let year = String(Array(id.characters)[0...1])
    
    return year == "20"
}

// Where the messenger is.
var messengerPath: String {
    let rawPath: NSString = "~/Library/Containers/com.tenic.EA-Center/"
    let absolutePath = rawPath.expandingTildeInPath
    let appPath = absolutePath + "/EA Center Messenger.app"
    
    return appPath
}

// Where the messenger is.
var messengerParentPath: String {
    let rawPath: NSString = "~/Library/Containers/com.tenic.EA-Center/"
    let absolutePath = rawPath.expandingTildeInPath
    
    return absolutePath
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate, NSPopoverDelegate, NSMenuDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var messageDate: NSTextField!
    @IBOutlet weak var messageTitle: NSTextField!
    @IBOutlet var message: NSTextView!
    @IBOutlet weak var popover: NSPopover!
    @IBOutlet weak var fullscreenButton: NSButton!
    @IBOutlet weak var previousMessages: NSMenu!
    @IBOutlet weak var popButton: NSButton!
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var topBanner: NSImageView!
    @IBOutlet weak var commentLoadImage: LoadImage!
    
    @IBOutlet weak var commentTable: NSTableView!
    @IBOutlet weak var comment: NSTextField!
    @IBOutlet weak var noComments: NSTextField!
    @IBOutlet weak var splitview: NSSplitView!
    @IBOutlet weak var lockscreen: NSView!
    
    @IBOutlet weak var likeButton: NSButton!
    @IBOutlet weak var numberOfLikes: NSTextField!
    
    var visibleComments = [UserComment]() {
        didSet (oldValue) {
            if visibleComments != oldValue {
                commentTable.reloadData()
//                commentTable.scrollToEndOfDocument(nil)
            }
        }
    }
    
    func regularizeID(_ id: String) -> String? {
        if ["99999999", "SSEA"].contains(id) {
            return id
        } else if ![10,8].contains(id.characters.count) || Int(id) == nil || !["0", "1"].contains(String(id.characters.last!)) {
            return nil
        } else if id.characters.count == 8 && !id.hasPrefix("20") {
            return "20" + id
        } else {
            return id
        }
    }
    
    var appStudentID: String {
        let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
        var identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? [String:String]()
        return identity["ID"] ?? "_"
    }
    
    var muted: Bool {
        let path: NSString = "~/Library/Application Support/Find my EA/.mute"
        let fm = FileManager()
        return fm.fileExists(atPath: path.expandingTildeInPath)
    }
        
    
    var hasRunAlert = false

    var fullDate = "" {
        didSet {
            if fullDate != "" {
                commentLoadImage.startAnimation()
                Thread.sleep(forTimeInterval: 0)
                loadComments(fullDate, explicit: false)
            }
        }
    }
    
    var recallMenu = NSMenu()
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {

        window.delegate = self
        
        displayFormatter.locale = Locale(identifier: "en_US")
        formatter.locale = Locale(identifier: "en_US")
        commentDateFormatter.locale = Locale(identifier: "en_US")

        
        displayFormatter.dateFormat = displayDateFormat
        displayFormatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = longDateFormat
        displayFormatter.locale = Locale(identifier: "en_US")
        commentDateFormatter.dateFormat = commentDateShortFormat
        commentDateFormatter.locale = Locale(identifier: "en_US")
        
        window.backgroundColor = NSColor(white: 1, alpha: 1)
        messageTitle.stringValue = ""
//        window.styleMask |= NSTexturedBackgroundWindowMask
        fetchAnnouncements()
        window.standardWindowButton(NSWindowButton.zoomButton)!.isHidden = true
        window.standardWindowButton(NSWindowButton.miniaturizeButton)!.isHidden = true
        window.standardWindowButton(.closeButton)!.isHidden = true
        window.titlebarAppearsTransparent = true
//        window.movableByWindowBackground = true
        window.backgroundColor = NSColor(red: 239/255, green: 248/255, blue: 1, alpha: 1)
        let nib = NSNib(nibNamed: "Comment", bundle: Bundle.main)
        commentTable.register(nib!, forIdentifier: "Comment")
        commentTable.selectionHighlightStyle = .none
        
        recallMenu.addItem(withTitle: "Recall", action: #selector(AppDelegate.recallMessage), keyEquivalent: "")
        recallMenu.delegate = self
        commentTable.menu = recallMenu
        splitview.setPosition(splitview.maxPossiblePositionOfDivider(at: 0), ofDividerAt: 0)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let command = Terminal(launchPath: "/usr/bin/osascript", arguments: ["-e", "tell application \"System Events\" to get name of every login item"])
        let existingLoginItems = command.exec()
        if !existingLoginItems.contains("EA Center Messenger") {
            command.arguments = ["-e", "tell application \"System Events\" to make login item at end with properties {name: \"EA Center Messenger\", path: \"\(messengerParentPath + "/EA Center Messenger.app")\", hidden: true}"]
            command.exec()
            NSApplication.shared().hide(nil)
        }
    }
    
    
    func applicationWillBecomeActive(_ notification: Notification) {
        if FileManager().fileExists(atPath: dataPath + ".history") && FileManager().fileExists(atPath: dataPath + ".cache.tenic") {
            Terminal().deleteFileWithPath(dataPath + ".history")
            updateToLatestMessage()
            if messageTitle.stringValue != "" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        } else if !window.isVisible {
            window.orderOut(nil)
            NSApplication.shared().hide(nil)
        }
        
        comment.isEnabled = FileManager().fileExists(atPath: dataPath + ".identity.tenic")
    }
    func applicationWillResignActive(_ notification: Notification) {
        window.orderOut(nil)
    }
    
    func getLatestDate(_ receivedMessages: [String:String]) -> (date: String, newestDate: Date) {
        let dates = Array(receivedMessages.keys)
        var newestDate = Date(timeIntervalSinceReferenceDate: 0) //Old date
        var tmpfulldate = ""
        for i in dates {
            let tmp = receivedMessages[i]!.components(separatedBy: "\u{2028}")
            if formatter.date(from: i)!.timeIntervalSince(newestDate) > 0 && !["", "Find my EA", "Found my EA"].contains(tmp[0]) {
                tmpfulldate = i
                newestDate = formatter.date(from: i)!
            }
        }
        return (tmpfulldate, newestDate)
    }
    
    func updateToLatestMessage() {
        if var receivedMessages = NSKeyedUnarchiver.unarchiveObject(withFile: dataPath + ".cache.tenic") as? [String:String] {
            let tmp = getLatestDate(receivedMessages)
            fullDate = tmp.date
            if tmp.newestDate.timeIntervalSinceReferenceDate == 0 {
                print("no date is available")
                return
            }
            let newDateString = formatter.string(from: tmp.newestDate)
            let cache = receivedMessages[newDateString]!.components(separatedBy: "\u{2028}")
            if cache.count < 3 {
                Terminal().deleteFileWithPath(dataPath)
                return
            }
            let title = cache[0]
            let message = cache[1]
            let likes = cache[2]
            window.makeKeyAndOrderFront(nil)
            let displayDate = displayFormatter.string(from: tmp.newestDate)
            updateMessage(title, date: displayDate, message: message, likes: likes)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func exitFullScreen(_ sender: NSButton) {
        window.toggleFullScreen(nil)
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        topBanner.isHidden = true
        closeButton.isHidden = true
        fullscreenButton.isEnabled = true
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        fullscreenButton.isEnabled = false
        topBanner.isHidden = false
        closeButton.isHidden = false
        closeButton.image = #imageLiteral(resourceName: "closebutton_focused")
    }

    var dataPath: String {
        let manager = FileManager()
        let rawPath: NSString = "~/Library/Application Support/Find my EA/"
        let folder: String = rawPath.expandingTildeInPath + "/"
        if !(manager.fileExists(atPath: folder)) {
            //system("mkdir -p ~/Library/Application\\ Support/Innovation\\ Center")
            let command = Terminal(launchPath: "/bin/mkdir", arguments: ["-p", folder])
            command.exec()
        } else {
            Terminal(launchPath: "/usr/bin/chflags", arguments: ["hidden", folder]).exec()
        }
        
        return String(folder)
    }
    
    func fetchAnnouncements() {
        let url = URL(string: serverAddress + "tenicCore/Announcements.php")!
        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in
            if error != nil {
                print("error=\(error!)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {self.fetchAnnouncements()}
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                if let tmp = json as? NSDictionary {
                    self.sortMessages(tmp as! [String:String])
                }
            } catch let err as NSError {
                print(err)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(globalDelay)) {self.fetchAnnouncements()}
        }
        task.resume()
    }
    
    func sortMessages(_ messages: [String:String]) {
        var receivedMessages = [String:String]()
        if FileManager().fileExists(atPath: self.dataPath + ".cache.tenic"), let cache = NSKeyedUnarchiver.unarchiveObject(withFile: self.dataPath + ".cache.tenic") as?
            [String:String] {
            receivedMessages = cache
        }
        let existingMessages = Array(receivedMessages.keys)
        let newMessageKeys = Array(messages.keys).filter({msg -> Bool in
            return !existingMessages.contains(msg)
        })
        let announcementcount = newMessageKeys.filter({key -> Bool in
            let msg = messages[key]!.components(separatedBy: "\u{2028}")
            return !["Find my EA", "Found my EA"].contains(msg[1]) && passEntireFilter(msg[0])}).count
        if announcementcount >= 5 {
            displayNotification(["", "EA Center", "You have just received \(announcementcount) messages.", ""], date: formatter.string(from: Date()))
        }
        
        for i in newMessageKeys {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(newMessageKeys.index(of: i)! * 2)) {
                var msg = messages[i]!.components(separatedBy: "\u{2028}")
                for m in 0..<msg.count {
                    msg[m] = msg[m].decodedString()
                }
                if self.passEntireFilter(msg[0]) {
                    if announcementcount < 5 {
                        self.displayNotification(msg, date: i)
                    }
                    if msg[1] == "Find my EA" || msg[1] == "Found my EA" || msg[1] == "<lock>" {
                        msg[1] = ""
                    }
                    receivedMessages[i] = msg[1...3].joined(separator: "\u{2028}")
                } else {
                    print("not displayed: \"\(msg[0])\"")
                }
            
                if i == newMessageKeys.last {
                    NSKeyedArchiver.archiveRootObject(receivedMessages, toFile: self.dataPath + ".cache.tenic")
                }
                
            }
        }

    }
    
    func displayNotification(_ message: [String], date: String) {
        if muted {return}
        var message = message
        message.removeFirst()
        if message[0] == "" {
            return
        }

        // A lock is detected
        
        if message[0] == "<lock>" {
            DispatchQueue.main.async {
                let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
                var identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? [String:String]()
                identity["Lock"] = message[1]
                NSKeyedArchiver.archiveRootObject(identity, toFile: path.expandingTildeInPath)
            }
            if FileManager().fileExists(atPath: "/Applications/Find my EA.app") {
                let command = Terminal(launchPath: "/usr/bin/open", arguments: ["Applications/Find my EA.app"])
                command.exec()
            }
            return
        }
        
        let notification = NSUserNotification()
        notification.title = message[0]
        notification.informativeText = message[1]
        if message[0] == "Find my EA" || message[0] == "Found my EA" {
            notification.hasActionButton = false
            notification.otherButtonTitle = "Got it"
        } else {
            notification.hasActionButton = true
            if message[0] == "EA Center" {
                notification.actionButtonTitle = "View Latest"
            } else {
                notification.actionButtonTitle = "Read More"
            }
            notification.otherButtonTitle = "Dismiss"
        }
        notification.setValue(true, forKey: "_showsButtons")
        if message[0] != "EA Center" {
            notification.userInfo = ["Title": message[0], "Date": date, "Message": message[1], "Likes": message[2]]
        }
        notification.deliveryDate = Date(timeIntervalSinceNow: 1)
        notification.soundName = nil
        
        NSUserNotificationCenter.default.delegate = self
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        DispatchQueue.main.async {
            NSSound(named: "Alert")?.play()
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if NSEvent.modifierFlags().contains(.option) {
            NSUserNotificationCenter.default.removeAllDeliveredNotifications()
        }
        if notification.otherButtonTitle == "Got it" {
            if FileManager().fileExists(atPath: "/Applications/Find my EA.app") {
                let command = Terminal(launchPath: "/usr/bin/open", arguments: ["Applications/Find my EA.app"])
                command.exec()
            }
            return
        }
        if notification.actionButtonTitle == "View Latest" {
            let string:NSString = "~/Library/Application Support/Find my EA/.history"
            let command = Terminal(launchPath: "/bin/mkdir", arguments: ["-p", string.expandingTildeInPath])
            command.execUntilExit()
            updateToLatestMessage()
            isActive = true
            Thread.detachNewThreadSelector(#selector(AppDelegate.refreshComments), toTarget: self, with: nil)
            return
        }
        fullDate = notification.userInfo!["Date"] as! String
        let sentDate = formatter.date(from: fullDate)!
        updateMessage(notification.userInfo!["Title"] as! String, date: displayFormatter.string(from: sentDate), message: notification.userInfo!["Message"] as! String, likes: notification.userInfo!["Likes"] as! String)
        let string:NSString = "~/Library/Application Support/Find my EA/.history"
        let command = Terminal(launchPath: "/bin/mkdir", arguments: ["-p", string.expandingTildeInPath])
        command.execUntilExit()
        loadComments(notification.userInfo!["Date"] as! String, explicit: true)
        window.makeKeyAndOrderFront(nil)
        isActive = true
        DispatchQueue.global(qos: .background).async {
            self.refreshComments()
        }
    }
    
    var isActive = false
    var isProcessing = false
    
    func refreshComments() {
        if !isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.refreshComments()
            }
            return
        }
        let url = URL(string: serverAddress + "tenicCore/FetchComments.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postString = "date=\(fullDate)"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil || !self.isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.refreshComments()
                }
                return
            }
            DispatchQueue.main.async {
                if error != nil {
                    print(error!)
                    self.noComments.stringValue = "Connection error."
                    return
                }
            }
            
            do {
                var json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSArray as! [Any]
                let likes = json.removeLast() as? [String: String]
                
                DispatchQueue.main.async {
                    if likes == nil {
                        self.likeButton.isEnabled = false
                        self.likeButton.toolTip = "Message has been deleted from the server."
                    } else {
                        self.likeButton.isEnabled = true
                    }
                    
                    
                    var comments = [[String:String]]()
                    for i in json {
                        comments.append(i as! [String: String])
                    }
                    
                    var receivedMessages = NSKeyedUnarchiver.unarchiveObject(withFile: self.dataPath + ".cache.tenic") as! [String:String]
                    var contentItem = receivedMessages[self.fullDate]!.components(separatedBy: "\u{2028}")
                    
                    if likes != nil {
                        let l = likes!["Likes"]!.components(separatedBy: " | ")
                        
                        if l.contains(self.appStudentID) {
                            self.likeButton.image = #imageLiteral(resourceName: "like")
                            self.likeButton.toolTip = "Un-like"
                        } else {
                            self.likeButton.image = #imageLiteral(resourceName: "like_outline")
                            self.likeButton.toolTip = "Like"
                        }
                        
                        self.numberOfLikes.integerValue = (l.count == 1 && l[0] == "") ? 0 : l.count
                        contentItem[2] = l.joined(separator: " | ")
                    }
                    
                    receivedMessages[self.fullDate] = contentItem.joined(separator: "\u{2028}")
                    NSKeyedArchiver.archiveRootObject(receivedMessages, toFile: self.dataPath + ".cache.tenic")
                    
                    
                    if !self.isProcessing {
                        self.visibleComments = comments.map {item -> UserComment in
                            return UserComment(username: item["User"]!, id: item["ID"]!, commentDate: item["Date"]!, comment: item["Comment"]!.decodedString())
                        }
                        self.noComments.stringValue = self.visibleComments.count == 0 ? "No comments." : ""
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.refreshComments()
                }
            } catch {
                print(String(data: data!, encoding: String.Encoding.utf8)!)
            }
        }
        
        task.resume()
    }
    
    func updateMessage(_ title: String, date: String, message: String, likes: String) {
        messageTitle.stringValue = title
        messageDate.stringValue = date
        numberOfLikes.integerValue = likes != "" ? likes.components(separatedBy: " | ").count : 0
        likeButton.image = likes.contains(appStudentID) ? #imageLiteral(resourceName: "like") : #imageLiteral(resourceName: "like_outline")
        self.message.string = message
        let pstyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        pstyle.paragraphSpacing = 7
        pstyle.lineSpacing = 3
        self.message.defaultParagraphStyle = pstyle
        self.message.textStorage?.addAttribute(NSParagraphStyleAttributeName, value: pstyle, range: NSMakeRange(0, self.message.textStorage!.length))
        self.message.font = NSFont(name: "Source Sans Pro", size: 13.5)
        self.message.scrollPageUp(nil)
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        isActive = true
        DispatchQueue.global(qos: .background).async {
            self.refreshComments()
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        isActive = true
    }
    
    func windowDidResignKey(_ notification: Notification) {
        isActive = false
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        isActive = false
        NSApplication.shared().hide(self)
        return true
    }
    
    @IBAction func pop(_ sender: NSButton) {
        
        previousMessages.removeAllItems()
        let tmp = previousMessages.addItem(withTitle: "Choose an earlier message...", action: "", keyEquivalent: "")
        tmp.isEnabled = false
        tmp.state = 0
        
        if !FileManager().fileExists(atPath: dataPath + ".cache.tenic") {return}
        
        let receivedMessages = NSKeyedUnarchiver.unarchiveObject(withFile: dataPath + ".cache.tenic") as? [String:String] ?? [String:String]()
        let receivedDates = Array(receivedMessages.keys)

        for i in ["Within 24 hours", "Last 1-7 days", "Last 8-30 days", "Earlier Messages"] {
            
            var availableDates = [Date]()
            
            switch i {
            case "Within 24 hours":
                for i in receivedDates {
                    let date = formatter.date(from: i)!
                    if Date().timeIntervalSince(date) <= 86400 {
                        availableDates.append(date)
                    }
                }
            case "Last 1-7 days":
                for i in receivedDates {
                    let date = formatter.date(from: i)!
                    if Date().timeIntervalSince(date) <= 86400 * 7 && Date().timeIntervalSince(date) > 86400 {
                        availableDates.append(date)
                    }
                }
            case "Last 8-30 days":
                for i in receivedDates {
                    let date = formatter.date(from: i)!
                    if Date().timeIntervalSince(date) <= 86400 * 30 && Date().timeIntervalSince(date) > 86400 * 7 {
                        availableDates.append(date)
                    }
                }
            case "Earlier Messages":
                for i in receivedDates {
                    let date = formatter.date(from: i)!
                    if Date().timeIntervalSince(date) > 86400 * 30 {
                        availableDates.append(date)
                    }
                }
            default:
                break
            }
            
            let menu = NSMenu(title: i)
            menu.delegate = self
            
            availableDates = availableDates.sorted(by: {date1, date2 -> Bool in
                return date1.timeIntervalSince(date2) < 0
            })
            
            for date in availableDates {
                let dateString = formatter.string(from: date)
                print(dateString)
                let title = receivedMessages[dateString]!.components(separatedBy: "\u{2028}")[0]
                if title != "" {
                    let item = menu.addItem(withTitle: title, action: #selector(AppDelegate.changeMessage(_:)), keyEquivalent: "")
                    item.toolTip = dateString
                    if dateString == fullDate {item.state = 1}
                }
            }
            
            let item = previousMessages.addItem(withTitle: i, action: nil, keyEquivalent: "")
            previousMessages.setSubmenu(menu, for: item)
        }
        
        // Pop the popover
        popover.behavior = .transient
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }
    
    var previousThreads = 0
    
    @IBAction func like(_ sender: NSButton) {
        
        if appStudentID == "_" {return}
        
        previousThreads += 1
        
        self.isActive = false
        sender.image = sender.image == #imageLiteral(resourceName: "like") ? #imageLiteral(resourceName: "like_outline") : #imageLiteral(resourceName: "like")
        if sender.image == #imageLiteral(resourceName: "like") {
            numberOfLikes.integerValue += 1
        } else {
            numberOfLikes.integerValue -= 1
        }
        if numberOfLikes.integerValue < 0 {numberOfLikes.integerValue = 0}
        
        let url = URL(string: serverAddress + "tenicCore/LikeAnnouncement.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "date=\(fullDate)&like=\(sender.image == #imageLiteral(resourceName: "like") ? 1 : 0)&id=\(appStudentID)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            self.previousThreads -= 1
            if error != nil {
                print(error!)
                return
            } else if let number = Int(String(data: data!, encoding: .utf8)!), self.previousThreads == 0 {
                DispatchQueue.main.async {
                    self.numberOfLikes.integerValue = number
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.isActive = true
                }
            }
            
        }
        task.resume()
    }
    
    func changeMessage(_ sender: NSMenuItem) {
        var receivedMessages = NSKeyedUnarchiver.unarchiveObject(withFile: dataPath + ".cache.tenic") as! [String:String]
        let msg = receivedMessages[sender.toolTip!]!.components(separatedBy: "\u{2028}")
        if NSEvent.modifierFlags() == .option {
            let alert = NSAlert()
            alert.messageText = "Delete Message?"
            alert.informativeText = "You cannot undo this action."
            alert.icon = NSApplication.shared().applicationIconImage
            alert.window.title = "EA Center Messenger"
            alert.addButton(withTitle: "OK").keyEquivalent = "\r"
            alert.addButton(withTitle: "Cancel")
            if !hasRunAlert {
                for i in alert.window.contentView!.subviews {
                    if let _ = i as? NSButton {
                        
                    } else {
                        i.setFrameOrigin(NSMakePoint(i.frame.origin.x, i.frame.origin.y - 23))
                    }
                    i.appearance = NSAppearance(named: NSAppearanceNameAqua)
                }
                hasRunAlert = true
            }
            customizeAlert(alert, height: 0, barPosition: 0)
            if alert.runModal() != NSAlertFirstButtonReturn {return}
            if fullDate == sender.toolTip! {
                print("Changing message to: " + fullDate)
                let receivedDates = Array(receivedMessages.keys)
                var availableDates = [Date]()
                for i in receivedDates {
                    let tmp = receivedMessages[i]!.components(separatedBy: "\u{2028}")
                    if !["", "Find my EA", "Found my EA"].contains(tmp[0]) {
                        availableDates.append(formatter.date(from: i)!)
                    }
                }
                receivedMessages[sender.toolTip!] = "\u{2028}"
                NSKeyedArchiver.archiveRootObject(receivedMessages, toFile: dataPath + ".cache.tenic")
                availableDates = availableDates.sorted(by: {date1, date2 -> Bool in
                    return date1.timeIntervalSince(date2) < 0
                })
                let currentIndex = availableDates.index(of: formatter.date(from: sender.toolTip!)!) ?? -1
                if currentIndex == -1 || availableDates.count == 1 {
                    messageTitle.stringValue = ""
                    message.string = ""
                    messageDate.stringValue = ""
                    fullDate = ""
                } else {
                    let index = currentIndex == 0 ? 1 : -1
                    fullDate = formatter.string(from: availableDates[currentIndex + index])
                    let nextMessage = receivedMessages[fullDate]!.components(separatedBy: "\u{2028}")
                    let nextDate = displayFormatter.string(from: availableDates[currentIndex + index])
                    updateMessage(nextMessage[0], date: nextDate, message: nextMessage[1], likes: nextMessage[2])
                    loadComments(nextDate, explicit: false)
                }
                sender.menu?.removeItem(sender)
                return
            } else {
                receivedMessages[sender.toolTip!] = "\u{2028}"
                NSKeyedArchiver.archiveRootObject(receivedMessages, toFile: dataPath + ".cache.tenic")
                sender.menu?.removeItem(sender)
            }
        } else {
            fullDate = sender.toolTip!
            commentTable.menu?.removeAllItems()
            popover.close()
            let tmp = formatter.date(from: sender.toolTip!)!
            self.isActive = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {self.isActive = true}
            updateMessage(msg[0], date: displayFormatter.string(from: tmp), message: msg[1], likes: msg[2])
            for i in sender.menu!.items {
                i.state = 0
            }
            sender.state = 1
        }
    }
    
    func passEntireFilter(_ filter: String) -> Bool {
        if filter == "" {return true}
        if !FileManager().fileExists(atPath: dataPath + ".identity.tenic") {return false}
        let sections = filter.components(separatedBy: "&&")
        for i in sections {
            if !passSectionFilter(i) {return false}
        }
        return true
    }
    
    func passSectionFilter(_ filter: String) -> Bool {
        for i in filter.components(separatedBy: "||") {
            if passSingleFilter(i) {return true}
        }
        return false
    }
    
    func passSingleFilter(_ filter: String) -> Bool {
        let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
        let identity = (NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) ?? [String:String]()) as! [String:String]
        if identity.count == 0 {return false}
        let entry = filter.components(separatedBy: ":")
        if entry.count != 2 {return false}
        if identity["ID"]! == "Test" {return false}
        switch entry[0] {
        case "G":
            if appStudentID.characters.count < 10 {return false}
            let min = Int(entry[1].components(separatedBy: "-")[0]) ?? 6
            let max = Int(entry[1].components(separatedBy: "-")[1]) ?? 12
            
            let entryYear = String(Array(appStudentID.characters)[2...3])
            var entryGrade = String(Array(appStudentID.characters)[7...8])
            if entryGrade == "16" {
                entryGrade = "0"
            } else if entryGrade == "15" {
                entryGrade = "-1"
            } else if entryGrade == "14" {
                entryGrade = "-2"
            } else if entryGrade == "13" {
                entryGrade = "-3"
            }
            
            let date = Date().addingTimeInterval(-86400 * 30 * 7) // August
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "y"
            formatter.locale = Locale(identifier: "en_US")
            let currentGrade = Int(yearFormatter.string(from: date))! - 2000 - Int(String(entryYear))! + Int(String(entryGrade))!
            return currentGrade <= max && currentGrade >= min
        case "I":
            return entry[1].contains(identity["ID"]!)
        case "E":
            let EAs = identity["EAs"]?.components(separatedBy: ", ") ?? [String]()
            for i in EAs {
                let range = NSString(string: entry[1]).range(of: i, options: .caseInsensitive)
                if range.location != NSNotFound {return true}
            }
            return false
        case "A":
            return entry[1].contains(identity["Advisory"]!) || identity["Advisory"]!.contains(entry[1])
        default:
            return false
        }
    }
    
    
    func customizeAlert(_ alert: NSAlert, height: CGFloat, barPosition: CGFloat) {
        alert.window.styleMask.insert(.fullSizeContentView)
        alert.window.titlebarAppearsTransparent = true
        //        alert.window.movableByWindowBackground = true
        alert.window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        alert.window.backgroundColor = NSColor.white
        alert.window.contentView?.wantsLayer = true
        alert.window.styleMask.insert(.resizable)
        alert.window.standardWindowButton(.zoomButton)!.isHidden = true
        alert.window.standardWindowButton(.closeButton)!.isHidden = true
        alert.window.standardWindowButton(.miniaturizeButton)!.isHidden = true
        alert.window.contentView?.layer?.backgroundColor = NSColor(red: 0.18, green: 0.39, blue: 0.52, alpha: 1).cgColor
        alert.window.setFrame(NSRect(origin: alert.window.frame.origin, size: NSMakeSize(alert.window.contentView!.frame.width, alert.window.contentView!.frame.height + 22)), display: true)
        
        alert.window.maxSize = alert.window.contentView!.frame.size
        alert.window.maxSize.height += height
        alert.window.minSize = alert.window.maxSize
        alert.window.maxSize.height -= 15
        
        let textSize = genericCalculateHeightForFont(NSFont.systemFont(ofSize: 11), text: alert.informativeText, width: 288, label: true)
        print(alert.informativeText)
        print("calculated size: \(textSize)")
        
        let bar = NSImageView(frame: NSMakeRect(0, 90 + (textSize < 41 ? 41 : textSize) + barPosition, alert.window.frame.width, 23))
        
//        let bar = NSImageView(frame: NSMakeRect(0, barPosition+1, alert.window.frame.width, 23))
        bar.imageScaling = .scaleAxesIndependently
        bar.image = #imageLiteral(resourceName: "top_gradient")
        bar.alphaValue = 1
        alert.window.contentView?.addSubview(bar)
        for i in alert.window.contentView!.subviews {
            i.appearance = NSAppearance(named: NSAppearanceNameAqua)
            if let tmp = i as? NSTextField {
                tmp.textColor = NSColor(red: 0.98, green: 0.92, blue: 0.6, alpha: 1)
            }
        }
    }
    
    @IBAction func sendComment(_ sender: NSTextField) {
        if fullDate == "" || sender.stringValue == "" || appStudentID == "_" {return}
        isProcessing = true
        let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
        var identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? [String:String]()
        let url = URL(string: serverAddress + "tenicCore/SubmitComment.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let username = identity["ID"] ?? "0"
        let postString = "user=\(username)&msg=\(fullDate)&commentdate=\(formatter.string(from: Date()))&comment=\(sender.stringValue.encodedString())"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error != nil {
                print("error: \(error!)")
                return
            }
            if String(data: data!, encoding: String.Encoding.utf8)! == "success" {
                self.isProcessing = false
                DispatchQueue.main.async {
                    self.loadComments(self.fullDate, explicit: true)
                }
            }
            
        }
        task.resume()
        sender.stringValue = ""
    }
    
    // Datasource and delegate methods
    
    var userIdentity = ""
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
        let identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? ["Name": "Anonymous", "Advisory": ""]
        userIdentity = identity["Name"]! + "(" + identity["Advisory"]! + ")"
        
//        noComments.stringValue = visibleComments.count != 0 ? "" : "No comments."
        
        return visibleComments.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = commentTable.make(withIdentifier: "Comment", owner: self) as! Comment
        cell.username.stringValue = visibleComments[row].username == userIdentity ? "You" : visibleComments[row].username
        cell.timestamp = visibleComments[row].commentDateString
        let comment_date = formatter.date(from: visibleComments[row].commentDateString)!
        cell.date = commentDateFormatter.string(from: comment_date)
        cell.userComment.stringValue = visibleComments[row].comment
        
        cell.senderID = visibleComments[row].id
        
        cell.userComment.textColor = NSColor.black
        if cell.userComment.stringValue.hasPrefix("b||") {
            cell.userComment.font = NSFont(name: "Helvetica Bold", size: 13)
            cell.userComment.stringValue = cell.userComment.stringValue.components(separatedBy: "b||")[1]
        } else if cell.userComment.stringValue.hasPrefix("i||") {
            cell.userComment.font = NSFont(name: "Helvetica Neue Italic", size: 13)
            cell.userComment.stringValue = cell.userComment.stringValue.components(separatedBy: "i||")[1]
        } else if cell.userComment.stringValue.contains("||") {
            let c = cell.userComment.stringValue.components(separatedBy: "||")
            if c[0].characters.count == 6 {
                if let color = getColorFromString(c[0]) {
                    cell.userComment.textColor = color
                    cell.userComment.stringValue = c[1]
                    cell.userComment.font = NSFont(name: "Helvetica Neue", size: 13)
                }
            }
        } else {
            cell.userComment.font = NSFont(name: "Helvetica Neue", size: 13)
        }
        
        cell.userComment.frame = NSMakeRect(185, 14, commentTable.frame.width - 204, calculateHeightForFont(NSFont(name: cell.userComment.font!.fontName, size: 13)!, text: visibleComments[row].comment))
        print("\(commentTable.frame.width - 204) | \(cell.userComment.frame.height)")
        
        return cell
    }
    
    func calculateHeightForFont(_ font: NSFont, text: String) -> CGFloat {
        let textfield = AutoResizingTextField()
        textfield.isBezeled = false
        textfield.isBordered = false
        textfield.drawsBackground = false
        textfield.frame = NSMakeRect(0,0, commentTable.frame.width - 204, 22)
        textfield.font = font
        textfield.cell?.wraps = true
        textfield.stringValue = text
        return textfield.intrinsicContentSize.height
    }
    
    func genericCalculateHeightForFont(_ font: NSFont, text: String, width: CGFloat, label: Bool) -> CGFloat {
        let textfield = AutoResizingTextField()
        textfield.frame = NSMakeRect(0,0, width, 22)
        textfield.font = font
        textfield.stringValue = text
        if label {
            textfield.frame = NSMakeRect(0, 0, width + 2, 22)
            textfield.isBordered = false
            textfield.isBezeled = false
        }
        return textfield.intrinsicContentSize.height
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        
        var fontName = "Helvetica Neue"
        if visibleComments[row].comment.hasPrefix("b||") {fontName = "Helvetica Bold"}
        if visibleComments[row].comment.hasPrefix("i||") {fontName = "Helvetica Neue Italic"}
        
        var comment = visibleComments[row].comment
        if comment.hasPrefix("b||") {comment = comment.components(separatedBy: "b||")[1]}
        if comment.hasPrefix("i||") {comment = comment.components(separatedBy: "i||")[1]}
        if comment.components(separatedBy: "||")[0].characters.count == 6 {
            comment = comment.components(separatedBy: "||")[1]
        }
        
        return calculateHeightForFont(NSFont(name: fontName, size: 13)!, text: comment) + 23
    }
    
    let implicitDateFormat = "y/M/d"
    
    @IBAction func reloadComments(_ sender: NSButton) {
        commentLoadImage.startAnimation()
        noComments.stringValue = ""
        loadComments(fullDate, explicit: false)
    }
    
    func loadComments(_ dateKey: String, explicit: Bool) {
        self.visibleComments.removeAll()
        noComments.stringValue = ""
        if NSEvent.modifierFlags() == .option {return}
        let url = URL(string: serverAddress + "tenicCore/FetchComments.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postString = "date=\(dateKey)"
        var hasRun = false
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if hasRun {return}
            DispatchQueue.main.async {
                self.commentLoadImage.stopAnimation()
                if error != nil {
                    print(error!)
                    self.noComments.stringValue = "Connection error."
                    return
                } else if data == nil {
                    self.noComments.stringValue = "No comments."
                }
            }
            do {
                if String(data: data!, encoding: String.Encoding.utf8)! == "" {
                    DispatchQueue.main.async {
                        self.visibleComments.removeAll()
                        self.noComments.stringValue = "No comments."
                    }
                    return
                }
                var json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSArray as! [Any]
                let likes = json.removeLast() as? [String: String]
                DispatchQueue.main.async {
                    if likes == nil {
                        self.likeButton.isEnabled = false
                        self.likeButton.toolTip = "Message has been deleted from the server."
                    } else {
                        self.likeButton.isEnabled = true
                    }
                    
                    
                    var comments = [[String:String]]()
                    for i in json {
                        comments.append(i as! [String: String])
                    }
                    
                    var receivedMessages = NSKeyedUnarchiver.unarchiveObject(withFile: self.dataPath + ".cache.tenic") as! [String:String]
                    var contentItem = receivedMessages[self.fullDate]!.components(separatedBy: "\u{2028}")
                    
                    if likes != nil {
                        let l = likes!["Likes"]!.components(separatedBy: " | ")
                        
                        if l.contains(self.appStudentID) {
                            self.likeButton.image = #imageLiteral(resourceName: "like")
                            self.likeButton.toolTip = "Un-like"
                        } else {
                            self.likeButton.image = #imageLiteral(resourceName: "like_outline")
                            self.likeButton.toolTip = "Like"
                        }
                        
                        self.numberOfLikes.integerValue = (l.count == 1 && l[0] == "") ? 0 : l.count
                        contentItem[2] = l.joined(separator: " | ")
                    }

                    
                    receivedMessages[dateKey] = contentItem.joined(separator: "\u{2028}")
                    NSKeyedArchiver.archiveRootObject(receivedMessages, toFile: self.dataPath + ".cache.tenic")

                    self.visibleComments = comments.map {item -> UserComment in
                        return UserComment(username: item["User"]!, id: item["ID"]!, commentDate: item["Date"]!, comment: item["Comment"]!.decodedString())
                    }
                    
                    self.noComments.stringValue = self.visibleComments.count == 0 ? "No comments." : ""
                    
                    if explicit {
                        self.commentTable.scrollToEndOfDocument(nil)
                    }
                }
            } catch {
                print(String(data: data!, encoding: String.Encoding.utf8)!)
            }
            hasRun = true
        }
    
        task.resume()
    }
    
    var rightclickRowIndex = -1
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == splitView.subviews[1]
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu != recallMenu {return}
        isProcessing = true
        let cursor = NSEvent.mouseLocation()
        let cursorInWindow = NSPoint(x: cursor.x - (window.frame.origin.x), y: cursor.y - (window.frame.origin.y))
        rightclickRowIndex = commentTable.row(at: commentTable.convert(cursorInWindow, from: window.contentView!))
        if rightclickRowIndex == -1 {commentTable.menu?.removeAllItems(); return}
        let cell = commentTable.view(atColumn: 0, row: rightclickRowIndex, makeIfNecessary: false) as! Comment
        commentTable.menu?.removeAllItems()
        if appStudentID == cell.senderID {
            commentTable.menu?.addItem(withTitle: "Recall Comment", action: #selector(AppDelegate.recallMessage), keyEquivalent: "")
        }
    }
    
    func menuDidClose(_ menu: NSMenu){
        if menu != recallMenu {return}
        isProcessing = false
        Thread.detachNewThreadSelector(#selector(AppDelegate.refreshComments), toTarget: self, with: nil)
    }
    
    func recallMessage() {
        if rightclickRowIndex == -1 {return}
        isProcessing = true
        let cell = commentTable.view(atColumn: 0, row: rightclickRowIndex, makeIfNecessary: false) as? Comment
        let url = URL(string: serverAddress + "tenicCore/RecallComment.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "msg=\(fullDate)&time=\(cell!.timestamp)".data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print("error = \(error!)")
                return
            }
            if String(data: data!, encoding: String.Encoding.utf8)!.contains("success") {
                self.isProcessing = false
                DispatchQueue.main.async {
                    
                    if self.commentTable.numberOfRows == 0 {
                        self.noComments.stringValue = "No comments."
                    } else {
                        self.commentTable.removeRows(at: IndexSet(integer: self.rightclickRowIndex), withAnimation: .effectFade)
                    }
                }
            } else {
                print(String(data: data!, encoding: String.Encoding.utf8)!)
            }
        }
        task.resume()
    }
    
}

// Image class

let database = ["Cloud Sync": (108, 19)]

class LoadImage: NSImageView {
    
    var isAnimating = false
    var imageName = "Cloud Sync"
    var max = 0
    var breakpoint = 0
    var fps = 25.0
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    var currentThread: Thread?
    
    let resourcePath = Bundle.main.resourcePath!
    
    func startAnimation() {
        if currentThread != nil && !currentThread!.isCancelled {return}
        self.image = nil
        max = database[imageName]!.0
        breakpoint = database[imageName]!.1
        self.isHidden = false
        isAnimating = true
        currentThread = Thread(target: self, selector: #selector(LoadImage.loop), object: nil)
        currentThread!.start()
    }
    
    func stopAnimation() {
        isAnimating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.currentThread?.cancel()
        }
    }
    
    func loop() {
        var currentFrame = 0
        while isAnimating {
            let name = imageName + "_" + String(format: "%03d", currentFrame) + ".png"
            let tmp = NSImage(contentsOfFile: resourcePath + "/" + imageName + "/" + name)
            DispatchQueue.main.async {self.image = tmp!}
            currentFrame = currentFrame < max ? currentFrame + 1 : breakpoint
            Thread.sleep(forTimeInterval: 1 / fps - 0.005)
        }
        self.isHidden = true
        return
    }
}
