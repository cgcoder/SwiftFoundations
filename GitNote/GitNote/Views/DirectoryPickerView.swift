import SwiftUI

struct DirectoryPickerView: View {
    @ObservedObject var noteManager: NoteManager
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Choose Notes Directory")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select a directory to store your markdown notes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Select Directory") {
                showingDirectoryPicker = true
            }
            .buttonStyle(.borderedProminent)
            .fileImporter(
                isPresented: $showingDirectoryPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        noteManager.setRootDirectory(url)
                    }
                case .failure(let error):
                    print("Error selecting directory: \(error)")
                }
            }
        }
        .frame(maxWidth: 400)
        .padding()
    }
}