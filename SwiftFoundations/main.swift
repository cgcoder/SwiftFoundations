//
//  main.swift
//  SwiftFoundations
//
//  Created by Gopinath Chandrasekaran on 1/1/26.
//

import Foundation

struct FilePath: Hashable, CustomStringConvertible {
    let path: String
    // confirm to customStringConvertible, get
    var description: String { path }
    
    init?(path: String) {
        guard path.hasPrefix("/") else { return nil }
        guard !path.utf8.contains(0) else { return nil }
        
        self.path = FilePath.normalized(path)
    }
    
    var url: URL { URL(fileURLWithPath: self.path, isDirectory: self.path.hasSuffix("/")) }
    
    func appending(component: String) -> FilePath? {
        guard !component.isEmpty else { return nil }
        guard !component.hasPrefix("/") else { return nil }
        guard !component.utf8.contains(0) else { return nil }
        
        let newUrl = self.url.appendingPathComponent(component, isDirectory: false)
        return FilePath(path: newUrl.path)
    }
    
    static func normalized(_ path: String) -> String {
        var normalizedPath = ""
        var prevWasSlash: Bool = false
        
        for ch in path {
            if ch == "/" {
                if !prevWasSlash {
                    normalizedPath.append(ch)
                }
                prevWasSlash = true
            }
            else {
                prevWasSlash = false
                normalizedPath.append(ch)
            }
        }
        
        return normalizedPath
    }
}
