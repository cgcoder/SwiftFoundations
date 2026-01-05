import Foundation

struct Note: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var fileName: String
    var folderPath: String
    var createdAt: Date
    var modifiedAt: Date
    var isContentLoaded: Bool = false
    
    var filePath: String {
        return folderPath.isEmpty ? fileName : "\(folderPath)/\(fileName)"
    }
    
    init(title: String, content: String = "", fileName: String, folderPath: String = "", isContentLoaded: Bool = false) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.fileName = fileName.hasSuffix(".json") ? fileName : "\(fileName).json"
        self.folderPath = folderPath
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isContentLoaded = isContentLoaded
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct NoteContent: Codable {
    let title: String
    let body: String
}