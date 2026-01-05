import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var noteManager: NoteManager
    @Binding var note: Note?
    @State private var editableContent: String = ""
    @State private var editableTitle: String = ""
    @State private var showingPreview = false
    
    var body: some View {
        if let currentNote = note {
            Group {
                if showingPreview {
                    MarkdownPreviewView(content: editableContent, noteId: currentNote.id.uuidString)
                } else {
                    TextEditor(text: $editableContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
            .navigationTitle(editableTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(showingPreview ? "Edit" : "Preview") {
                        showingPreview.toggle()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .onAppear {
                editableContent = currentNote.content
                editableTitle = currentNote.title
            }
            .onChange(of: note) {
                if let newNote = note {
                    editableContent = newNote.content
                    editableTitle = newNote.title
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveNote)) { _ in
                saveNote()
            }
        } else {
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("Select a note to edit")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("GitNote")
        }
    }
    
    private func saveNote() {
        guard var currentNote = note else { return }
        
        // Clear cache for this note since content is being updated
        MarkdownCacheManager.shared.clearCacheForNote(currentNote.id.uuidString)
        
        currentNote.content = editableContent
        currentNote.modifiedAt = Date()
        
        noteManager.saveNote(currentNote)
        
        if let index = noteManager.notes.firstIndex(where: { $0.id == currentNote.id }) {
            noteManager.notes[index] = currentNote
        }
        
        note = currentNote
    }
}