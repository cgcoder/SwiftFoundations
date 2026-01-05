//
//  GitNoteApp.swift
//  GitNote
//
//  Created by Gopinath chandrasekaran on 1/3/26.
//

import SwiftUI

@main
struct GitNoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Note") {
                Button("Save Note") {
                    NotificationCenter.default.post(name: .saveNote, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let saveNote = Notification.Name("saveNote")
}
