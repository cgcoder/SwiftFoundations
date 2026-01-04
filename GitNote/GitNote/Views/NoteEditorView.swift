import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var noteManager: NoteManager
    @Binding var note: Note?
    @State private var editableContent: String = ""
    @State private var editableTitle: String = ""
    @State private var showingPreview = false
    
    var body: some View {
        if let currentNote = note {
            VStack(spacing: 0) {
                HStack {
                    TextField("Note Title", text: $editableTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack {
                        Button(showingPreview ? "Edit" : "Preview") {
                            showingPreview.toggle()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            saveNote()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
                Divider()
                
                if showingPreview {
                    MarkdownPreviewView(content: editableContent)
                } else {
                    TextEditor(text: $editableContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
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
        } else {
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("Select a note to edit")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func saveNote() {
        guard var currentNote = note else { return }
        
        currentNote.content = editableContent
        currentNote.title = editableTitle
        currentNote.modifiedAt = Date()
        
        noteManager.saveNote(currentNote)
        
        if let index = noteManager.notes.firstIndex(where: { $0.id == currentNote.id }) {
            noteManager.notes[index] = currentNote
        }
        
        note = currentNote
    }
}