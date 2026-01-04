import SwiftUI
import AppKit

struct SidebarView: View {
    @ObservedObject var noteManager: NoteManager
    @Binding var selectedNote: Note?
    @State private var expandedFolders: Set<String> = []
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var selectedFolderForNewFolder = ""
    
    var body: some View {
        List(selection: $selectedNote) {
            Section("Notes") {
                ForEach(rootFolders, id: \.id) { folder in
                    FolderRowView(
                        folder: folder,
                        noteManager: noteManager,
                        selectedNote: $selectedNote,
                        expandedFolders: $expandedFolders
                    )
                }
                
                ForEach(rootNotes, id: \.id) { note in
                    NoteRowView(note: note)
                        .tag(note)
                }
                .onDelete(perform: deleteRootNotes)
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("New Note") {
                    createNewNote()
                }
                
                Button("New Folder") {
                    showingNewFolderAlert = true
                }
            }
            
            ToolbarItemGroup(placement: .secondaryAction) {
                Menu("Settings") {
                    Button("Change Root Directory") {
                        changeRootDirectory()
                    }
                    
                    Button("Show Config File") {
                        showConfigFile()
                    }
                }
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                if !newFolderName.isEmpty {
                    _ = noteManager.createFolder(name: newFolderName, parentPath: selectedFolderForNewFolder)
                    newFolderName = ""
                    selectedFolderForNewFolder = ""
                }
            }
        }
    }
    
    private var rootFolders: [NoteFolder] {
        return noteManager.folders.filter { $0.parentPath == nil || $0.parentPath?.isEmpty == true }
    }
    
    private var rootNotes: [Note] {
        return noteManager.notes.filter { $0.folderPath.isEmpty }
    }
    
    private func createNewNote() {
        let title = "New Note \(noteManager.notes.count + 1)"
        if let note = noteManager.createNote(title: title) {
            selectedNote = note
        }
    }
    
    private func deleteRootNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = rootNotes[index]
            noteManager.deleteNote(note)
        }
    }
    
    private func changeRootDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select"
        openPanel.message = "Choose new root directory for notes"
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                noteManager.setRootDirectory(url)
            }
        }
    }
    
    private func showConfigFile() {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".gitnote.config.json")
        NSWorkspace.shared.selectFile(configPath.path, inFileViewerRootedAtPath: "")
    }
}

struct FolderRowView: View {
    let folder: NoteFolder
    @ObservedObject var noteManager: NoteManager
    @Binding var selectedNote: Note?
    @Binding var expandedFolders: Set<String>
    
    private var isExpanded: Bool {
        expandedFolders.contains(folder.fullPath)
    }
    
    private var childFolders: [NoteFolder] {
        noteManager.folders.filter { $0.parentPath == folder.fullPath }
    }
    
    private var childNotes: [Note] {
        noteManager.notes.filter { $0.folderPath == folder.fullPath }
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { isExpanded },
                set: { expanded in
                    if expanded {
                        expandedFolders.insert(folder.fullPath)
                    } else {
                        expandedFolders.remove(folder.fullPath)
                    }
                }
            )
        ) {
            ForEach(childFolders, id: \.id) { childFolder in
                FolderRowView(
                    folder: childFolder,
                    noteManager: noteManager,
                    selectedNote: $selectedNote,
                    expandedFolders: $expandedFolders
                )
            }
            
            ForEach(childNotes, id: \.id) { note in
                NoteRowView(note: note)
                    .tag(note)
            }
        } label: {
            Label(folder.name, systemImage: "folder")
        }
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        Label(note.title, systemImage: "doc.text")
    }
}