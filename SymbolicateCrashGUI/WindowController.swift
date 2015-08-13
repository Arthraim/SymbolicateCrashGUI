//
//  WindowController.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/7/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func changeLogAction(sender: AnyObject) {
        (contentViewController as! ViewController).changeLogFile()
    }

    @IBAction func changeAllAction(sender: AnyObject) {
        (contentViewController as! ViewController).changeAllFiles()
    }
}
