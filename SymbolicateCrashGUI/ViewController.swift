//
//  ViewController.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/6/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa
import DJProgressHUD_OSX

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

    func doSymbolicateIfNeeded() {
        // when everything is ready, do symbolicate
        if let appFilename = appFilename,
            dysmFilename = dysmFilename,
            crashFilename = crashFilename {
                if appFilename != "" && dysmFilename != "" && crashFilename != "" {
                    DJProgressHUD.showStatus("Initializing...", fromView: self.draggableView)
                    doSymbolicate(appFilename: appFilename, dysmFilename: dysmFilename, crashFilename: crashFilename)
                }
        }
    }

    func handleFilenames(_ filenames: [String]) -> (Bool) {
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
        doSymbolicateIfNeeded()
        return successOnce
    }

    func changeLogFile () {
        crashFilename = ""
        crashFileText.stringValue = ""
    }

    func changeAllFiles () {
        appFilename = ""
        appFileText.stringValue = ""
        dysmFilename = ""
        dysmFileText.stringValue = ""
        crashFilename = ""
        crashFileText.stringValue = ""
    }

    func doSymbolicate(appFilename: String, dysmFilename: String, crashFilename: String) {
        // export DEVELOPER_DIR=`xcode-select -p`;alias symbolicate='/Applications/Xcode.app//Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash';symbolicate -v '1438759250.308397.crash' > '1438759250.308397.symbolicated.crash'

        // create a temporary directory for .app .dsym .crash files
        DJProgressHUD.showStatus("Creating directory...", fromView: self.draggableView)
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.desktopDirectory, FileManager.SearchPathDomainMask.userDomainMask, true);
        let workingDirectory = "\(paths[0])/symbolicateWorkspace\(arc4random_uniform(1000))/"
        do {
            try FileManager.default.createDirectory(atPath: workingDirectory, withIntermediateDirectories:true, attributes:nil)
        } catch _ {
            // TODO: handle error
            return
        }

        // copy files to this directory
        DJProgressHUD.showStatus("Copying files...", fromView: self.draggableView)
        do {
            try FileManager.default.copyItem(atPath: appFilename, toPath: "\(workingDirectory)tmp.app")
            try FileManager.default.copyItem(atPath: dysmFilename, toPath: "\(workingDirectory)tmp.dYSM")
            try FileManager.default.copyItem(atPath: crashFilename, toPath: "\(workingDirectory)tmp.crash")
        } catch _ {
            // TODO: handle error
            return
        }

        // read cached symbolicatecrash path
        var symbolicateCrashPath = UserDefaults.standard.string(forKey: "NSUserDefaultsKey.symbolicatecrashPath")

        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: { () -> Void in

            if symbolicateCrashPath == nil {
                // get user's xcode path
                DispatchQueue.main.async(execute: { () -> Void in
                    DJProgressHUD.showStatus("Locating Xcode...", fromView: self.draggableView)
                })
                var xcodePath: String = "/Applications/Xcode.app/"
                let xcodeSelectCommand = "xcode-select -p"
                if let output = self.runShellCommand(xcodeSelectCommand) {
                    let components = output.components(separatedBy: "Xcode.app")
                    if components.count > 0 {
                        xcodePath = "\(components[0])Xcode.app/"
                    }
                } else {
                    // TODO: handle error
                    return
                }

                // get user's symbolicatecrash path
                DispatchQueue.main.async(execute: { () -> Void in
                    DJProgressHUD.showStatus("Locating SymbolicateCrash...", fromView: self.draggableView)
                })
                symbolicateCrashPath = "\(xcodePath)Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash"
                let symolicateCrashCommand = "find '\(xcodePath)' -name symbolicatecrash -type f"
                if let output = self.runShellCommand(symolicateCrashCommand) {
                    symbolicateCrashPath = (output as String).replacingOccurrences(of: "\n", with: "", options: NSString.CompareOptions.literal, range: nil)
                    UserDefaults.standard.setValue(symbolicateCrashPath, forKey: "NSUserDefaultsKey.symbolicatecrashPath")
                    UserDefaults.standard.synchronize()
                } else {
                    // TODO: handle error
                    return
                }
            }

            DispatchQueue.main.async(execute: { () -> Void in
                DJProgressHUD.showStatus("Runing SymbolicateCrash...", fromView: self.draggableView)
            })
            let command = "export DEVELOPER_DIR=`xcode-select -p`;'\(symbolicateCrashPath!)' -v '\(workingDirectory)tmp.crash' > '\(workingDirectory)tmp.symbolicated.crash'"
            let logOutput = self.runShellCommand(command)

            DispatchQueue.main.async(execute: { () -> Void in
                if let logOutput = logOutput {
                    NSWorkspace.shared().openFile("\(workingDirectory)tmp.symbolicated.crash")
                    DJProgressHUD.showStatus("Done!", fromView: self.draggableView)
                } else {
                    DJProgressHUD.showStatus("SymbolicateCrash fail", fromView: self.draggableView)
                }
                DJProgressHUD.dismiss()
            })
        }) // end of async closure
    }

    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        return true
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }

    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        return false
    }

    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return false
    }

    func runShellCommand(_ command: String) -> NSString? {
        var output: String?

        let pipe = Pipe()

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.standardOutput = pipe

        let file: FileHandle = pipe.fileHandleForReading

        task.launch()

        let data: Data = file.readDataToEndOfFile()

        return NSString(data:data, encoding:String.Encoding.utf8)
    }

}

