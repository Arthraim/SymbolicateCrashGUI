//
//  DraggableView.swift
//  SymbolicateCrashGUI
//
//  Created by Arthur Wang on 8/6/15.
//  Copyright (c) 2015 YangApp.com. All rights reserved.
//

import Cocoa

class DraggableView: NSView {

    var callback: ((_ filenames: [String]) -> (Bool))?

    override func awakeFromNib() {
        wantsLayer = true
        register(forDraggedTypes: [NSFilenamesPboardType])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        layer!.backgroundColor = NSColor(calibratedRed: 0.835, green: 0.875, blue: 0.753, alpha: 1).cgColor
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        layer!.backgroundColor = nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        layer!.backgroundColor = nil

        let pboard: NSPasteboard = sender.draggingPasteboard()
        if let filenames = pboard.propertyList(forType: NSFilenamesPboardType) as? [String],
            let callback = callback {
                return callback(filenames: filenames)
        }
        return false
    }
}
