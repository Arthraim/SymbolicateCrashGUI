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
    @IBOutlet weak var dysmFileText: NSTextField!
    @IBOutlet weak var crashFileText: NSTextField!

    var dysmFilename: String?
    var crashFilename: String?

    override func awakeFromNib() {
        draggableView.callback = handleFilenames
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func doSymbolicateIfNeeded() {
        // when everything is ready, do symbolicate
        if let dysmFilename = dysmFilename,
            let crashFilename = crashFilename {
                if dysmFilename != "" && crashFilename != "" {
                    DJProgressHUD.showStatus("Initializing...", from: self.draggableView)
                    doSymbolicate(dysmFilename: dysmFilename, crashFilename: crashFilename)
                }
        }
    }

    func handleFilenames(_ filenames: [String]) -> (Bool) {
        var successOnce: Bool = false
        for filename in filenames {
            NSLog("daggred %@", filename)
            if filename.hasSuffix(".dSYM") {
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
        dysmFilename = ""
        dysmFileText.stringValue = ""
        crashFilename = ""
        crashFileText.stringValue = ""
    }

    func doSymbolicate(dysmFilename: String, crashFilename: String) {
        // export DEVELOPER_DIR=`xcode-select -p`;alias symbolicate='/Applications/Xcode.app//Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash';symbolicate -v '1438759250.308397.crash' > '1438759250.308397.symbolicated.crash'

        // create a temporary directory for .app .dsym .crash files
        DJProgressHUD.showStatus("Creating directory...", from: self.draggableView)
        var paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.desktopDirectory, FileManager.SearchPathDomainMask.userDomainMask, true);
        let workingDirectory = "\(paths[0])/symbolicateWorkspace\(arc4random_uniform(1000))/"
        do {
            try FileManager.default.createDirectory(atPath: workingDirectory, withIntermediateDirectories:true, attributes:nil)
        } catch _ {
            // TODO: handle error
            return
        }

        // copy files to this directory
        DJProgressHUD.showStatus("Copying files...", from: self.draggableView)
        do {
            try FileManager.default.copyItem(atPath: dysmFilename, toPath: "\(workingDirectory)tmp.dYSM")
            try FileManager.default.copyItem(atPath: crashFilename, toPath: "\(workingDirectory)tmp.crash")
        } catch _ {
            // TODO: handle error
            return
        }

        // read cached symbolicatecrash path
        var symbolicateCrashPath = UserDefaults.standard.string(forKey: "NSUserDefaultsKey.symbolicatecrashPath")

        DispatchQueue.global(qos: .background).async(execute: { () -> Void in

            if symbolicateCrashPath == nil {
                // get user's xcode path
                DispatchQueue.main.async(execute: { () -> Void in
                    DJProgressHUD.showStatus("Locating Xcode...", from: self.draggableView)
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
                    DJProgressHUD.showStatus("Locating SymbolicateCrash...", from: self.draggableView)
                })
                symbolicateCrashPath = "\(xcodePath)Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash"
                let symolicateCrashCommand = "find '\(xcodePath)' -name symbolicatecrash -type f | grep SharedFrameworks"
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
                DJProgressHUD.showStatus("Runing SymbolicateCrash...", from: self.draggableView)
            })
            let command = "export DEVELOPER_DIR=`xcode-select -p`;'\(symbolicateCrashPath!)' -v '\(workingDirectory)tmp.crash' > '\(workingDirectory)tmp.symbolicated.crash'"
            let logOutput = self.runShellCommand(command)

            DispatchQueue.main.async(execute: { () -> Void in
                if logOutput != nil {
                    NSWorkspace.shared.openFile("\(workingDirectory)tmp.symbolicated.crash")
                    DJProgressHUD.showStatus("Done!", from: self.draggableView)
                } else {
                    DJProgressHUD.showStatus("SymbolicateCrash fail", from: self.draggableView)
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

    func runShellCommand(_ command: String) -> String? {
        let pipe = Pipe()

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.standardOutput = pipe

        let file: FileHandle = pipe.fileHandleForReading

        task.launch()

        let data: Data = file.readDataToEndOfFile()

        return String(data: data, encoding: .utf8)
    }

}

