//
//  SlateApp.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

@main
struct SlateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SlateMenuCommands()
        }
    }
}

#if canImport(AppKit)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        if url.pathExtension == SlatePackage.packageExtension {
            if let (doc, _, _) = try? SlatePackage.load(from: url) {
                DocumentStore.shared.updateActiveDocument(doc)
                return true
            }
        }
        return false
    }
}
#endif
