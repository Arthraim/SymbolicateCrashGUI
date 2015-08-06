//
//  ViewController.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/6/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        if let layer = view.layer {
            layer.backgroundColor = NSColor.whiteColor().CGColor
        }
        (view as! DraggableView).callback = doSymbolicate;
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func doSymbolicate(appFilename: String, dysmFilename: String, crashFilename: String) {
        // export DEVELOPER_DIR=`xcode-select -p`;alias symbolicate='/Applications/Xcode.app//Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash';symbolicate -v '1438759250.308397.crash' > '1438759250.308397.symbolicated.crash'

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in

            let command = "export DEVELOPER_DIR=`xcode-select -p`;'/Applications/Xcode.app/Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash' -v '\(crashFilename)' > '1438759250.308397.symbolicated.crash'"

            let pipe = NSPipe()

            let task = NSTask()
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", command]
            task.standardOutput = pipe

            let file: NSFileHandle = pipe.fileHandleForReading

            task.launch()

            let data: NSData = file.readDataToEndOfFile()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let output = NSString(data:data, encoding:NSUTF8StringEncoding) {
                    NSLog("%@", output)
                } else {
                    NSLog("no output")
                }
            })

        }) // end of async closure
    }

}

