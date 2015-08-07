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

    override func awakeFromNib() {
        let visualEffectView = NSVisualEffectView(frame: NSMakeRect(0, 0, 300, 180))
        visualEffectView.material = NSVisualEffectMaterial.Dark
        visualEffectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        visualEffectView.state = NSVisualEffectState.Active

        if let window = window {
            window.styleMask = window.styleMask | NSFullSizeContentViewWindowMask
            window.titlebarAppearsTransparent = true
            //self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)

//            window.contentView.addSubview(visualEffectView)

//            window.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[visualEffectView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: ["visualEffectView":visualEffectView]))
//            window.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[visualEffectView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: ["visualEffectView":visualEffectView]))
        }
    }

}
