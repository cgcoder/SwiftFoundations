import Foundation

struct NoteFolder: Identifiable, Hashable {
    var id: UUID
    var name: String
    var path: String
    var parentPath: String?
    
    var fullPath: String {
        if let parent = parentPath, !parent.isEmpty {
            return "\(parent)/\(path)"
        }
        return path
    }
    
    init(name: String, path: String, parentPath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.parentPath = parentPath
    }
}