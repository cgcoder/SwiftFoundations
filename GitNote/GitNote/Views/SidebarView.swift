import SwiftUI
import AppKit

struct SidebarView: View {
    @ObservedObject var noteManager: NoteManager
    @Binding var selectedNote: Note?
    @State private var expandedFolders: Set<String> = []
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var selectedFolderForNewFolder = ""
    @State private var showingNewNoteAlert = false
    @State private var newNoteName = ""
    @State private var selectedFolder: NoteFolder? = nil
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSidebarFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarSection
            Divider()
            mainContentSection
        }
        .navigationTitle("Notes")
        .focusable()
        .focused($isSidebarFocused)
        .onAppear {
            isSidebarFocused = true
        }
        .onTapGesture {
            isSidebarFocused = true
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
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
        .alert("New Note", isPresented: $showingNewNoteAlert) {
            TextField("Note Name", text: $newNoteName)
            Button("Cancel", role: .cancel) {
                newNoteName = ""
            }
            Button("Create") {
                createNoteFromAlert()
            }
        }
    }
    
    private var toolbarSection: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: { 
                    selectedFolderForNewFolder = selectedFolder?.fullPath ?? ""
                    showingNewNoteAlert = true 
                }) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .help("New Note")
                
                Button(action: { 
                    selectedFolderForNewFolder = selectedFolder?.fullPath ?? ""
                    showingNewFolderAlert = true 
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                .help("New Folder")
                
                Spacer()
                
                Button(action: {
                    // TODO: Implement search functionality
                }) {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)
                .help("Search Notes")
                
                Button(action: {
                    // TODO: Implement export functionality
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .help("Export Notes")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var mainContentSection: some View {
        ZStack {
            noteListView
            searchOverlay
        }
    }
    
    private var noteListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rootFolders, id: \.id) { folder in
                    FolderRowView(
                        folder: folder,
                        noteManager: noteManager,
                        selectedNote: $selectedNote,
                        expandedFolders: $expandedFolders,
                        selectedFolder: $selectedFolder,
                        searchText: searchText
                    )
                }
                
                ForEach(rootNotes, id: \.id) { note in
                    NoteRowView(note: note, isSelected: selectedNote?.id == note.id, searchText: searchText)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleNoteSelection(note)
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var searchOverlay: some View {
        if isSearching && !searchText.isEmpty {
            VStack {
                Spacer()
                HStack {
                    Text("Search: \(searchText)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var rootFolders: [NoteFolder] {
        return noteManager.folders.filter { $0.parentPath == nil || $0.parentPath?.isEmpty == true }
    }
    
    private var rootNotes: [Note] {
        return noteManager.notes.filter { $0.folderPath.isEmpty }
    }
    
    private var searchResults: (folders: [NoteFolder], notes: [Note]) {
        if searchText.isEmpty {
            return ([], [])
        }
        
        let matchingFolders = noteManager.folders.filter { folder in
            folder.name.localizedCaseInsensitiveContains(searchText)
        }
        
        let matchingNotes = noteManager.notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText)
        }
        
        return (matchingFolders, matchingNotes)
    }
    
    private var firstSearchResult: (folder: NoteFolder?, note: Note?) {
        let results = searchResults
        return (results.folders.first, results.notes.first)
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
    
    private func createNoteFromAlert() {
        if !newNoteName.isEmpty {
            let folderPath = selectedFolderForNewFolder
            if let note = noteManager.createNote(title: newNoteName, folderPath: folderPath) {
                // Expand parent folder if note is created in a directory
                if !folderPath.isEmpty {
                    expandedFolders.insert(folderPath)
                }
                // Load content and select the note
                if let loadedNote = noteManager.loadNoteContent(note) {
                    selectedNote = loadedNote
                } else {
                    selectedNote = note
                }
                selectedFolder = nil
            }
            newNoteName = ""
            selectedFolderForNewFolder = ""
        }
    }
    
    private func handleNoteSelection(_ note: Note) {
        if let loadedNote = noteManager.loadNoteContent(note) {
            selectedNote = loadedNote
        } else {
            selectedNote = note
        }
        selectedFolder = nil
    }
    
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {        
        if keyPress.key == .escape {
            DispatchQueue.main.async {
                clearSearch()
            }
            return .handled
        } 
        
        if keyPress.key == .delete || keyPress.key == .deleteForward {
            if isSearching && !searchText.isEmpty {
                DispatchQueue.main.async {
                    searchText = String(searchText.dropLast())
                    if searchText.isEmpty {
                        clearSearch()
                    } else {
                        updateSearchResults()
                    }
                }
                return .handled
            }
        } 
        
        // Handle printable characters for search
        if !keyPress.characters.isEmpty {
            let char = keyPress.characters.first!
            if char.isLetter || char.isNumber || char.isWhitespace || char.isPunctuation || char.isSymbol {
                DispatchQueue.main.async {
                    if !isSearching {
                        startSearch()
                    }
                    searchText += keyPress.characters
                    updateSearchResults()
                }
                return .handled
            }
        }
        
        return .ignored
    }
    
    private func startSearch() {
        isSearching = true
        isSidebarFocused = true
    }
    
    private func clearSearch() {
        isSearching = false
        searchText = ""
    }
    
    private func updateSearchResults() {
        let results = searchResults
        
        // Expand parent folders for matching items
        for folder in results.folders {
            expandParentFolders(for: folder.fullPath)
        }
        
        for note in results.notes {
            if !note.folderPath.isEmpty {
                expandParentFolders(for: note.folderPath)
            }
        }
        
        // Select first result
        let firstResult = firstSearchResult
        if let firstFolder = firstResult.folder {
            selectedFolder = firstFolder
            selectedNote = nil
        } else if let firstNote = firstResult.note {
            if let loadedNote = noteManager.loadNoteContent(firstNote) {
                selectedNote = loadedNote
            } else {
                selectedNote = firstNote
            }
            selectedFolder = nil
        }
    }
    
    private func expandParentFolders(for path: String) {
        var currentPath = path
        while !currentPath.isEmpty {
            expandedFolders.insert(currentPath)
            if let lastSlash = currentPath.lastIndex(of: "/") {
                currentPath = String(currentPath[..<lastSlash])
            } else {
                break
            }
        }
    }
    
}

struct FolderRowView: View {
    let folder: NoteFolder
    @ObservedObject var noteManager: NoteManager
    @Binding var selectedNote: Note?
    @Binding var expandedFolders: Set<String>
    @Binding var selectedFolder: NoteFolder?
    let searchText: String
    
    
    private var childFolders: [NoteFolder] {
        noteManager.folders.filter { $0.parentPath == folder.fullPath }
    }
    
    private var childNotes: [Note] {
        noteManager.notes.filter { $0.folderPath == folder.fullPath }
    }
    
    private var isHighlighted: Bool {
        !searchText.isEmpty && folder.name.localizedCaseInsensitiveContains(searchText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {
                    print("Button clicked for folder: \(folder.name), path: \(folder.fullPath)")
                    print("Current expanded folders: \(expandedFolders)")
                    if expandedFolders.contains(folder.fullPath) {
                        print("Removing from expanded")
                        expandedFolders.remove(folder.fullPath)
                    } else {
                        print("Adding to expanded")
                        expandedFolders.insert(folder.fullPath)
                    }
                    print("New expanded folders: \(expandedFolders)")
                }) {
                    Image(systemName: expandedFolders.contains(folder.fullPath) ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                
                Label(folder.name, systemImage: "folder")
                    .foregroundColor(isHighlighted ? .accentColor : .primary)
                    .fontWeight(isHighlighted ? .semibold : .regular)
                    .onTapGesture {
                        selectedFolder = folder
                        selectedNote = nil
                    }
                
                Spacer()
            }
            .padding(4)
            .background(selectedFolder?.id == folder.id ? Color.accentColor.opacity(0.3) : Color.clear)
            .cornerRadius(4)
            
            if expandedFolders.contains(folder.fullPath) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(childFolders, id: \.id) { childFolder in
                        FolderRowView(
                            folder: childFolder,
                            noteManager: noteManager,
                            selectedNote: $selectedNote,
                            expandedFolders: $expandedFolders,
                            selectedFolder: $selectedFolder,
                            searchText: searchText
                        )
                        .padding(.leading, 16)
                    }
                    
                    ForEach(childNotes, id: \.id) { note in
                        NoteRowView(note: note, isSelected: selectedNote?.id == note.id, searchText: searchText)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let loadedNote = noteManager.loadNoteContent(note) {
                                    selectedNote = loadedNote
                                } else {
                                    selectedNote = note
                                }
                                selectedFolder = nil
                            }
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let isSelected: Bool
    let searchText: String
    
    private var isHighlighted: Bool {
        !searchText.isEmpty && note.title.localizedCaseInsensitiveContains(searchText)
    }
    
    var body: some View {
        HStack {
            Label(note.title, systemImage: "doc.text")
                .foregroundColor(isHighlighted ? .accentColor : .primary)
                .fontWeight(isHighlighted ? .semibold : .regular)
            Spacer()
        }
        .padding(4)
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        .cornerRadius(4)
    }
}
