//
//  ContentView.swift
//  GitNote
//
//  Created by Gopinath chandrasekaran on 1/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var noteManager = NoteManager()
    @State private var selectedNote: Note?
    
    var body: some View {
        Group {
            if !noteManager.isConfigLoaded {
                VStack {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if noteManager.rootDirectory == nil {
                DirectoryPickerView(noteManager: noteManager)
            } else {
                NavigationSplitView {
                    SidebarView(noteManager: noteManager, selectedNote: $selectedNote)
                        .navigationSplitViewColumnWidth(min: 250, ideal: 300)
                } detail: {
                    NoteEditorView(noteManager: noteManager, note: $selectedNote)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
