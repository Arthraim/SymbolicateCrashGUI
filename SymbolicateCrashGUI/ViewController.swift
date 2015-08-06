//
//  ViewController.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/6/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSSplitViewDelegate {

    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var draggableView: DraggableView!
    @IBOutlet weak var appFileText: NSTextField!
    @IBOutlet weak var dysmFileText: NSTextField!
    @IBOutlet weak var crashFileText: NSTextField!

    var appFilename: String?
    var dysmFilename: String?
    var crashFilename: String?

    override func awakeFromNib() {
        splitView.delegate = self
        draggableView.callback = handleFilenames
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func updateUI() {
        // when everything is ready, do symbolicate
        if let appFilename = appFilename,
            dysmFilename = dysmFilename,
            crashFilename = crashFilename {
                doSymbolicate(appFilename: appFilename, dysmFilename: dysmFilename, crashFilename: crashFilename)
        }
    }

    func handleFilenames(filenames: [String]) -> (Bool) {
        var successOnce: Bool = false
        for filename in filenames {
            NSLog("daggred %@", filename)
            if filename.hasSuffix(".app") {
                successOnce = true
                appFilename = filename
                appFileText.stringValue = filename
            } else if filename.hasSuffix(".dSYM") {
                successOnce = true
                dysmFilename = filename
                dysmFileText.stringValue = filename
            } else if filename.hasSuffix(".crash") {
                successOnce = true
                crashFilename = filename
                crashFileText.stringValue = filename
            }
        }
        updateUI()
        return successOnce
    }

    func doSymbolicate(#appFilename: String, dysmFilename: String, crashFilename: String) {
        // export DEVELOPER_DIR=`xcode-select -p`;alias symbolicate='/Applications/Xcode.app//Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash';symbolicate -v '1438759250.308397.crash' > '1438759250.308397.symbolicated.crash'


        // TODO: create a temporary directory for .app .dsym .crash files
        // TODO: write output file to there as well

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in

            // get user's xcode path
            var xcodePath: String = "/Applications/Xcode.app/"
            let xcodeSelectCommand = "xcode-select -p"
            if let output = self.runShellCommand(xcodeSelectCommand) {
                let components = output.componentsSeparatedByString("Xcode.app")
                if components.count > 0 {
                    xcodePath = "\(components[0] as! String)Xcode.app/"
                }
            } else {
                // TODO: handle error
                return
            }

            // get user's symbolicatecrash path
            var symolicateCrashPath: String = "\(xcodePath)Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash"
            let symolicateCrashCommand = "find '\(xcodePath)' -name symbolicatecrash -type f"
            if let output = self.runShellCommand(symolicateCrashCommand) {
                symolicateCrashPath = (output as String).stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            } else {
                // TODO: handle error
                return
            }

            let command = "export DEVELOPER_DIR=`xcode-select -p`;'\(symolicateCrashPath)' -v '\(crashFilename)' > '\(crashFilename).symbolicated.crash'"
            let logOutput = self.runShellCommand(command)

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let logOutput = logOutput {
                    NSLog("%@", logOutput)
                } else {
                    NSLog("no output")
                }
            })
        }) // end of async closure
    }

    func splitView(splitView: NSSplitView, shouldHideDividerAtIndex dividerIndex: Int) -> Bool {
        return true
    }

    func runShellCommand(command: String) -> NSString? {
        var output: String?

        let pipe = NSPipe()

        let task = NSTask()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.standardOutput = pipe

        let file: NSFileHandle = pipe.fileHandleForReading

        task.launch()

        let data: NSData = file.readDataToEndOfFile()

        return NSString(data:data, encoding:NSUTF8StringEncoding)
    }

}

