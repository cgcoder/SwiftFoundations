import Foundation

struct AppConfig: Codable {
    let rootDirectory: String
    let lastModified: Date
    
    init(rootDirectory: String) {
        self.rootDirectory = rootDirectory
        self.lastModified = Date()
    }
}