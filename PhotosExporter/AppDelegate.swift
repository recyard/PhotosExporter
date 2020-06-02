//
//  AppDelegate.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.10.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
            
    @IBOutlet var startTimeField: NSTextField!
    
    @IBOutlet var endTimeField: NSTextField!
    
    @IBOutlet var backDir: NSTextField!
    
    @IBOutlet var console: NSScrollView!

    @IBAction func exportButtonPressed(_ sender: NSButton) {
        export(subdir: backDir.stringValue, startTime: startTimeField.stringValue, endTime: endTimeField.stringValue, console: console.documentView!)
    }
    
//    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        window.close()
//        export()
//        NSApp.terminate(self)
//    }

}

