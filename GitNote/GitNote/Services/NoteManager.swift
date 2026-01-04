import Foundation

class NoteManager: ObservableObject {
    @Published var rootDirectory: URL?
    @Published var notes: [Note] = []
    @Published var folders: [NoteFolder] = []
    @Published var isConfigLoaded = false
    
    private let fileManager = FileManager.default
    private let configManager = ConfigManager.shared
    
    init() {
        loadConfigOnStartup()
    }
    
    private func loadConfigOnStartup() {
        if let config = configManager.loadConfig() {
            let url = URL(fileURLWithPath: config.rootDirectory)
            if fileManager.fileExists(atPath: url.path) {
                rootDirectory = url
                loadNotesAndFolders()
                isConfigLoaded = true
                return
            }
        }
        isConfigLoaded = true
    }
    
    func setRootDirectory(_ url: URL) {
        rootDirectory = url
        configManager.saveRootDirectory(url)
        loadNotesAndFolders()
    }
    
    func loadNotesAndFolders() {
        guard let rootURL = rootDirectory else { return }
        
        folders.removeAll()
        notes.removeAll()
        
        loadFoldersRecursively(at: rootURL, relativePath: "")
        loadNotesRecursively(at: rootURL, relativePath: "")
    }
    
    private func loadFoldersRecursively(at url: URL, relativePath: String) {
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            
            for item in contents {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    let folderName = item.lastPathComponent
                    let folderPath = relativePath.isEmpty ? folderName : "\(relativePath)/\(folderName)"
                    
                    let folder = NoteFolder(name: folderName, path: folderPath, parentPath: relativePath.isEmpty ? nil : relativePath)
                    folders.append(folder)
                    
                    loadFoldersRecursively(at: item, relativePath: folderPath)
                }
            }
        } catch {
            print("Error loading folders: \(error)")
        }
    }
    
    private func loadNotesRecursively(at url: URL, relativePath: String) {
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            
            for item in contents {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        let folderPath = relativePath.isEmpty ? item.lastPathComponent : "\(relativePath)/\(item.lastPathComponent)"
                        loadNotesRecursively(at: item, relativePath: folderPath)
                    } else if item.pathExtension.lowercased() == "json" {
                        loadNote(from: item, folderPath: relativePath)
                    }
                }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    private func loadNote(from url: URL, folderPath: String) {
        do {
            let data = try Data(contentsOf: url)
            let noteContent = try JSONDecoder().decode(NoteContent.self, from: data)
            let fileName = url.lastPathComponent
            
            let note = Note(title: noteContent.title, content: noteContent.body, fileName: fileName, folderPath: folderPath)
            notes.append(note)
        } catch {
            print("Error loading note \(url.lastPathComponent): \(error)")
        }
    }
    
    
    func createNote(title: String, folderPath: String = "") -> Note? {
        guard let rootURL = rootDirectory else { return nil }
        
        let fileName = "\(title).json"
        let fullFolderPath = folderPath.isEmpty ? rootURL : rootURL.appendingPathComponent(folderPath)
        let fileURL = fullFolderPath.appendingPathComponent(fileName)
        
        let noteContent = NoteContent(title: title, body: "")
        
        do {
            try fileManager.createDirectory(at: fullFolderPath, withIntermediateDirectories: true, attributes: nil)
            let data = try JSONEncoder().encode(noteContent)
            try data.write(to: fileURL)
            
            let note = Note(title: title, content: "", fileName: fileName, folderPath: folderPath)
            notes.append(note)
            return note
        } catch {
            print("Error creating note: \(error)")
            return nil
        }
    }
    
    func saveNote(_ note: Note) {
        guard let rootURL = rootDirectory else { return }
        
        let folderURL = note.folderPath.isEmpty ? rootURL : rootURL.appendingPathComponent(note.folderPath)
        let fileURL = folderURL.appendingPathComponent(note.fileName)
        
        let noteContent = NoteContent(title: note.title, body: note.content)
        
        do {
            let data = try JSONEncoder().encode(noteContent)
            try data.write(to: fileURL)
            
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].modifiedAt = Date()
            }
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    func deleteNote(_ note: Note) {
        guard let rootURL = rootDirectory else { return }
        
        let folderURL = note.folderPath.isEmpty ? rootURL : rootURL.appendingPathComponent(note.folderPath)
        let fileURL = folderURL.appendingPathComponent(note.fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            notes.removeAll { $0.id == note.id }
        } catch {
            print("Error deleting note: \(error)")
        }
    }
    
    func createFolder(name: String, parentPath: String = "") -> Bool {
        guard let rootURL = rootDirectory else { return false }
        
        let fullPath = parentPath.isEmpty ? name : "\(parentPath)/\(name)"
        let folderURL = rootURL.appendingPathComponent(fullPath)
        
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            
            let folder = NoteFolder(name: name, path: fullPath, parentPath: parentPath.isEmpty ? nil : parentPath)
            folders.append(folder)
            return true
        } catch {
            print("Error creating folder: \(error)")
            return false
        }
    }
}
