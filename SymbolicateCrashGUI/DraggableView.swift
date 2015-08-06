//
//  DraggableView.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/6/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa

class DraggableView: NSView {

    var callback: ((appFilename: String, dysmFilename: String, crashFilename: String) -> ())?
    var appFilename: String?
    var dysmFilename: String?
    var crashFilename: String?

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }

    override func awakeFromNib() {
        registerForDraggedTypes([NSFilenamesPboardType])
    }

    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return .Copy
    }

    override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        return .Copy
    }

    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        var pboard: NSPasteboard = sender.draggingPasteboard()
        if let filenames = pboard.propertyListForType(NSFilenamesPboardType) as? [String] {
            for filename in filenames {
                NSLog("daggred %@", filename)
                if filename.hasSuffix(".app") {
                    appFilename = filename
                } else if filename.hasSuffix(".dSYM") {
                    dysmFilename = filename
                } else if filename.hasSuffix(".crash") {
                    crashFilename = filename
                } else {
                    return false
                }
            }
            // when everything is ready, invoke callback
            if let appFilename = appFilename,
                   dysmFilename = dysmFilename,
                   crashFilename = crashFilename,
                   callback = callback {
                callback(appFilename: appFilename, dysmFilename: dysmFilename, crashFilename: crashFilename)
            }
        }
        return true
    }
}
