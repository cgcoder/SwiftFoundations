import Foundation

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    private let configFileName = ".gitnote.config.json"
    private var configFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(configFileName)
    }
    
    private init() {}
    
    func loadConfig() -> AppConfig? {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configFileURL)
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            return config
        } catch {
            print("Error loading config: \(error)")
            return nil
        }
    }
    
    func saveConfig(_ config: AppConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFileURL)
            print("Config saved to: \(configFileURL.path)")
        } catch {
            print("Error saving config: \(error)")
        }
    }
    
    func saveRootDirectory(_ url: URL) {
        let config = AppConfig(rootDirectory: url.path)
        saveConfig(config)
    }
    
    func configFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: configFileURL.path)
    }
    
    func deleteConfig() {
        do {
            try FileManager.default.removeItem(at: configFileURL)
        } catch {
            print("Error deleting config: \(error)")
        }
    }
}