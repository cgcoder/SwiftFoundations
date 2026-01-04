import Foundation

class MarkdownConverter {
    static func toHTML(_ markdown: String) -> String {
        var html = markdown
        
        html = convertHeaders(html)
        html = convertBold(html)
        html = convertItalic(html)
        html = convertCode(html)
        html = convertLinks(html)
        html = convertImages(html)
        html = convertLists(html)
        html = convertParagraphs(html)
        
        return wrapInHTMLDocument(html)
    }
    
    private static func convertHeaders(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        
        for line in lines {
            if line.hasPrefix("######") {
                let title = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                result.append("<h6>\(title)</h6>")
            } else if line.hasPrefix("#####") {
                let title = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                result.append("<h5>\(title)</h5>")
            } else if line.hasPrefix("####") {
                let title = line.dropFirst(4).trimmingCharacters(in: .whitespaces)
                result.append("<h4>\(title)</h4>")
            } else if line.hasPrefix("###") {
                let title = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                result.append("<h3>\(title)</h3>")
            } else if line.hasPrefix("##") {
                let title = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
                result.append("<h2>\(title)</h2>")
            } else if line.hasPrefix("#") {
                let title = line.dropFirst(1).trimmingCharacters(in: .whitespaces)
                result.append("<h1>\(title)</h1>")
            } else {
                result.append(line)
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func convertBold(_ text: String) -> String {
        return text.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
    }
    
    private static func convertItalic(_ text: String) -> String {
        return text.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
    }
    
    private static func convertCode(_ text: String) -> String {
        var result = text.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        
        result = result.replacingOccurrences(of: #"```(.+?)```"#, with: "<pre><code>$1</code></pre>", options: .regularExpression)
        
        return result
    }
    
    private static func convertLinks(_ text: String) -> String {
        return text.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
    }
    
    private static func convertImages(_ text: String) -> String {
        return text.replacingOccurrences(of: #"!\[(.+?)\]\((.+?)\)"#, with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)
    }
    
    private static func convertLists(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var inList = false
        var listItems: [String] = []
        
        for line in lines {
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                let item = String(line.dropFirst(2))
                listItems.append("<li>\(item)</li>")
                inList = true
            } else if line.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                let item = line.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression)
                listItems.append("<li>\(item)</li>")
                inList = true
            } else {
                if inList {
                    result.append("<ul>")
                    result.append(contentsOf: listItems)
                    result.append("</ul>")
                    listItems.removeAll()
                    inList = false
                }
                result.append(line)
            }
        }
        
        if inList {
            result.append("<ul>")
            result.append(contentsOf: listItems)
            result.append("</ul>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func convertParagraphs(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var currentParagraph: [String] = []
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !currentParagraph.isEmpty {
                    let paragraph = currentParagraph.joined(separator: " ")
                    if !paragraph.hasPrefix("<") {
                        result.append("<p>\(paragraph)</p>")
                    } else {
                        result.append(paragraph)
                    }
                    currentParagraph.removeAll()
                }
            } else if line.hasPrefix("<") {
                if !currentParagraph.isEmpty {
                    let paragraph = currentParagraph.joined(separator: " ")
                    result.append("<p>\(paragraph)</p>")
                    currentParagraph.removeAll()
                }
                result.append(line)
            } else {
                currentParagraph.append(line)
            }
        }
        
        if !currentParagraph.isEmpty {
            let paragraph = currentParagraph.joined(separator: " ")
            result.append("<p>\(paragraph)</p>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func wrapInHTMLDocument(_ body: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                }
                h1 { font-size: 2em; }
                h2 { font-size: 1.5em; }
                h3 { font-size: 1.3em; }
                h4 { font-size: 1.1em; }
                h5 { font-size: 1em; }
                h6 { font-size: 0.9em; }
                p { margin-bottom: 1em; }
                ul, ol { margin-bottom: 1em; padding-left: 2em; }
                li { margin-bottom: 0.5em; }
                code {
                    background-color: #f5f5f5;
                    padding: 0.2em 0.4em;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, monospace;
                    font-size: 0.9em;
                }
                pre {
                    background-color: #f5f5f5;
                    padding: 1em;
                    border-radius: 5px;
                    overflow-x: auto;
                }
                pre code {
                    background-color: transparent;
                    padding: 0;
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #1c1c1e;
                        color: #ffffff;
                    }
                    code, pre {
                        background-color: #2c2c2e;
                    }
                    a {
                        color: #0A84FF;
                    }
                }
            </style>
        </head>
        <body>
            \(body)
        </body>
        </html>
        """
    }
}