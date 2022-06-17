//
//  AppDelegate.swift
//  TextField Demo
//
//  Created by Darren Ford on 15/6/2022.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application

		let str = "a=🧖🏼‍♀️, b=💆‍♂️, c=🙆🏾"
		Swift.print(str.count)
		Swift.print(str.utf8.count)
		Swift.print(str.utf16.count)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}


}

