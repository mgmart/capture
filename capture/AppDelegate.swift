//
//  AppDelegate.swift
//  capture
//
//  Created by Mario Martelli on 18.12.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Cocoa
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    // register for getURL events
    NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleEvent(_:with:)),
                                                 forEventClass: AEEventClass(kInternetEventClass),
                                                 andEventID: AEEventID(kAEGetURL))
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // deregister from getURL events
    NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass),
                                                    andEventID: AEEventID(kAEGetURL))
  }
  
  @objc private func handleEvent(_ event: NSAppleEventDescriptor, with replyEvent: NSAppleEventDescriptor) {
    let customLog = OSLog(subsystem: "de.schnuddelhuddel.capture", category: "Category")
    guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
    let newString = urlString.replacingOccurrences(of: "%20%26%20", with: "%20+%20")
    guard let url = URL(string: newString) else { return }
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
        
        // Give emacs the focus
        // works best if all existing emacs frames are minimised
        switchToEmacs()
        
        // Execute emacsclient and log result
        os_log("%{public}@", log:customLog, type: .default,
               shell(command: "/usr/local/bin/emacsclient", arguments: ["-c", "-F",
                                                                        "((title . \"capture\") (left . (+ 550)) (top . (+ 400)) (width . 110) (height . 12))",
                                                                        capture])!)
        switchBack()
        
      }
    }
    // Log received URL
    os_log("Capture: %{public}@", log: customLog, type: .default, capture)
    os_log("URL: %{public}@", log: customLog, type: .default, url.absoluteString)
    // Terminate Application afterwards
    NSApplication.shared.terminate(self)
  }
  
  /// Calls external command line program
  /// - Parameters:
  ///   - command: name of external program
  ///   - arguments: arguments to pass to program
  /// - Returns: output of external program after execution
  private func shell(command: String, arguments: [String]) -> String?
  {
    let task = Process()
    task.launchPath = command
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return output
  }
  
  
  /// Causes switching to the calling App by invoking
  /// CMD-TAB vie AppleScript
  private func switchBack() {
    let script = """
tell application "System Events"
  key down command
  keystroke tab
  keystroke tab
  key code 123
  key up command
end tell
"""
    
    // TODO: Is there a better way to wait?
    sleep(1)
    
    if let scriptObject = NSAppleScript(source: script) {
      var errorDict: NSDictionary? = nil
      _ = scriptObject.executeAndReturnError(&errorDict)
      
      if let error = errorDict {
        print(error)
      }
    }
  }
  
  /// Activates Emacs to ensure that capture frame will be visible to the user
  private func switchToEmacs() {
    let script = """
  tell application "Emacs"
    activate
  end tell
  """
    
    if let scriptObject = NSAppleScript(source: script) {
      var errorDict: NSDictionary? = nil
      _ = scriptObject.executeAndReturnError(&errorDict)
      
      if let error = errorDict {
        print(error)
      }
    }
  }
}
