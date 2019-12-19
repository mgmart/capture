//
//  AppDelegate.swift
//  capture
//
//  Created by Mario Martelli on 18.12.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Cocoa
import OSLog

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    // register for getURL events
    NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleEvent(_:with:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // deregister from getURL events
    NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
  }
  
  @objc private func handleEvent(_ event: NSAppleEventDescriptor, with replyEvent: NSAppleEventDescriptor) {
    let customLog = OSLog(subsystem: "de.schnuddelhuddel.capture", category: "Category")
    guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
    guard let url = URL(string: urlString) else { return }
    var capture = "org-protocol://capture?"
    var ampersand = ""
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
      if components.scheme == "capture" {
        
        if let queryItems = components.queryItems {
          for queryItem in queryItems {
            if let qiv = queryItem.value {
              capture = capture + ampersand + queryItem.name + "=" + qiv
              ampersand = "&"
            }
          }
        }
        capture = "\"" + capture + "\""
        print(shell(command: "/usr/local/bin/emacsclient", arguments: ["-c", "-n",
            "-F", "((title . \"capture\") (left . (+ 550)) (top . (+ 400)) (width . 110) (height . 12))",
          capture])!)
        
        
        // Bring emacs to the front
        // https://stackoverflow.com/questions/43449190/swift-xcode-use-osascript-in-mac-app
        let script = NSAppleScript(source: "activate application \"Emacs\"")!
        var errorDict : NSDictionary?
        script.executeAndReturnError(&errorDict)
        if errorDict != nil { print(errorDict!) }
      }
    }
    os_log("Got: %{public}@", log: customLog, type: .default, url.absoluteString)
    NSApplication.shared.terminate(self)
  }
  
  private func shell(command: String, arguments: [String]) -> String?
  {
    let task = Process()
    task.launchPath = command
    task.arguments = arguments
//    for txt in arguments {
//      print("--" + txt + "--")
//    }

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return output
  }
}
