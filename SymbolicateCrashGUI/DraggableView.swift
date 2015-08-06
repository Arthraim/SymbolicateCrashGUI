//
//  DraggableView.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/6/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa

class DraggableView: NSView {

    var callback: ((filenames: [String]) -> (Bool))?

    override func awakeFromNib() {
        wantsLayer = true
        if let layer = layer {
            layer.backgroundColor = NSColor.whiteColor().CGColor
        }

        registerForDraggedTypes([NSFilenamesPboardType])
    }

    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        layer!.backgroundColor = NSColor(calibratedRed: 0.835, green: 0.875, blue: 0.753, alpha: 1).CGColor
        return .Copy
    }

    override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        return .Copy
    }

    override func draggingExited(sender: NSDraggingInfo?) {
        layer!.backgroundColor = NSColor.whiteColor().CGColor
    }

    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        var pboard: NSPasteboard = sender.draggingPasteboard()
        if let filenames = pboard.propertyListForType(NSFilenamesPboardType) as? [String],
            callback = callback {
                return callback(filenames: filenames)
        }
        return false
    }
}
