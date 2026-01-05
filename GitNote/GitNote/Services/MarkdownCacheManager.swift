import Foundation
import CryptoKit

class MarkdownCacheManager {
    static let shared = MarkdownCacheManager()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    private init() {
        let rootDirectory = fileManager.currentDirectoryPath
        cacheDirectory = URL(fileURLWithPath: rootDirectory).appendingPathComponent(".cache/.md_html")
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func getCacheFileName(for markdownContent: String, noteId: String) -> String {
        let contentHash = SHA256.hash(data: Data(markdownContent.utf8))
        let hashString = contentHash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(noteId)_\(hashString).html"
    }
    
    func getCachedHTML(for markdownContent: String, noteId: String) -> String? {
        let fileName = getCacheFileName(for: markdownContent, noteId: noteId)
        let filePath = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        do {
            let cachedHTML = try String(contentsOf: filePath, encoding: .utf8)
            return cachedHTML
        } catch {
            print("Error reading cached HTML: \(error)")
            return nil
        }
    }
    
    func cacheHTML(_ html: String, for markdownContent: String, noteId: String) {
        let fileName = getCacheFileName(for: markdownContent, noteId: noteId)
        let filePath = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try html.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Error caching HTML: \(error)")
        }
    }
    
    func clearCache() {
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
            for file in cacheFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
    
    func clearCacheForNote(_ noteId: String) {
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
            let noteFiles = cacheFiles.filter { $0.lastPathComponent.hasPrefix("\(noteId)_") }
            
            for file in noteFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error clearing cache for note: \(error)")
        }
    }
}