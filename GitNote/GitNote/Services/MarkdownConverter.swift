import Foundation

class MarkdownConverter {
    static func toHTML(_ markdown: String, noteId: String = "unknown") -> String {
        // Check cache first
        if let cachedHTML = MarkdownCacheManager.shared.getCachedHTML(for: markdown, noteId: noteId) {
            return cachedHTML
        }
        
        // Use improved markdown parsing
        let bodyHTML = parseMarkdownToHTML(markdown)
        
        // Wrap in complete HTML document
        let completeHTML = wrapInHTMLDocument(bodyHTML)
        
        // Cache the result
        MarkdownCacheManager.shared.cacheHTML(completeHTML, for: markdown, noteId: noteId)
        
        return completeHTML
    }
    
    private static func parseMarkdownToHTML(_ markdown: String) -> String {
        var html = markdown
        
        // Process in order to avoid conflicts
        html = convertCodeBlocks(html)
        html = convertInlineCode(html)
        html = convertHeaders(html)
        html = convertBold(html)
        html = convertItalic(html)
        html = convertStrikethrough(html)
        html = convertLinks(html)
        html = convertImages(html)
        html = convertLists(html)
        html = convertTables(html)
        html = convertBlockquotes(html)
        html = convertHorizontalRules(html)
        html = convertParagraphs(html)
        
        return html
    }
    
    private static func convertCodeBlocks(_ text: String) -> String {
        // Handle fenced code blocks first (```code```)
        let pattern = #"```(\w+)?\n(.*?)\n```"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: text.count)
        
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: "<pre><code class=\"language-$1\">$2</code></pre>"
        )
    }
    
    private static func convertInlineCode(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "<code>$1</code>",
            options: .regularExpression
        )
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
        return text.replacingOccurrences(
            of: #"\*\*([^*]+)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
    }
    
    private static func convertItalic(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"\*([^*]+)\*"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )
    }
    
    private static func convertStrikethrough(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"~~([^~]+)~~"#,
            with: "<del>$1</del>",
            options: .regularExpression
        )
    }
    
    private static func convertLinks(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#,
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )
    }
    
    private static func convertImages(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"!\[([^\]]*)\]\(([^)]+)\)"#,
            with: "<img src=\"$2\" alt=\"$1\">",
            options: .regularExpression
        )
    }
    
    private static func convertLists(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var inUnorderedList = false
        var inOrderedList = false
        var listItems: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") || trimmedLine.hasPrefix("+ ") {
                let item = String(trimmedLine.dropFirst(2))
                listItems.append("<li>\(item)</li>")
                if !inUnorderedList {
                    if inOrderedList {
                        result.append("</ol>")
                        inOrderedList = false
                    }
                    inUnorderedList = true
                }
            } else if let regex = try? NSRegularExpression(pattern: #"^\d+\.\s"#),
                      regex.firstMatch(in: trimmedLine, range: NSRange(location: 0, length: trimmedLine.count)) != nil {
                let item = trimmedLine.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression)
                listItems.append("<li>\(item)</li>")
                if !inOrderedList {
                    if inUnorderedList {
                        result.append("</ul>")
                        inUnorderedList = false
                    }
                    inOrderedList = true
                }
            } else {
                if inUnorderedList {
                    result.append("<ul>")
                    result.append(contentsOf: listItems)
                    result.append("</ul>")
                    inUnorderedList = false
                    listItems.removeAll()
                } else if inOrderedList {
                    result.append("<ol>")
                    result.append(contentsOf: listItems)
                    result.append("</ol>")
                    inOrderedList = false
                    listItems.removeAll()
                }
                result.append(line)
            }
        }
        
        // Handle remaining list items
        if inUnorderedList {
            result.append("<ul>")
            result.append(contentsOf: listItems)
            result.append("</ul>")
        } else if inOrderedList {
            result.append("<ol>")
            result.append(contentsOf: listItems)
            result.append("</ol>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func convertTables(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var inTable = false
        var tableRows: [String] = []
        
        for line in lines {
            if line.contains("|") && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let cells = line.components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                if !inTable {
                    inTable = true
                    tableRows.append("<table>")
                }
                
                if line.contains("---") || line.contains("===") {
                    // Skip separator row
                    continue
                }
                
                let cellsHTML = cells.map { "<td>\($0)</td>" }.joined()
                tableRows.append("<tr>\(cellsHTML)</tr>")
            } else {
                if inTable {
                    tableRows.append("</table>")
                    result.append(contentsOf: tableRows)
                    tableRows.removeAll()
                    inTable = false
                }
                result.append(line)
            }
        }
        
        // Handle remaining table
        if inTable {
            tableRows.append("</table>")
            result.append(contentsOf: tableRows)
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func convertBlockquotes(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var inBlockquote = false
        var blockquoteContent: [String] = []
        
        for line in lines {
            if line.hasPrefix("> ") {
                let content = String(line.dropFirst(2))
                blockquoteContent.append(content)
                if !inBlockquote {
                    inBlockquote = true
                }
            } else {
                if inBlockquote {
                    result.append("<blockquote>\(blockquoteContent.joined(separator: "<br>"))</blockquote>")
                    blockquoteContent.removeAll()
                    inBlockquote = false
                }
                result.append(line)
            }
        }
        
        // Handle remaining blockquote
        if inBlockquote {
            result.append("<blockquote>\(blockquoteContent.joined(separator: "<br>"))</blockquote>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func convertHorizontalRules(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.starts(with: "---") && trimmedLine.allSatisfy({ $0 == "-" }) {
                result.append("<hr>")
            } else {
                result.append(line)
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func convertParagraphs(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var currentParagraph: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                if !currentParagraph.isEmpty {
                    let paragraph = currentParagraph.joined(separator: " ")
                    if !paragraph.hasPrefix("<") && !paragraph.isEmpty {
                        result.append("<p>\(paragraph)</p>")
                    } else {
                        result.append(paragraph)
                    }
                    currentParagraph.removeAll()
                }
                result.append("")
            } else if line.hasPrefix("<") || line.contains("<table>") || line.contains("</table>") {
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
            if !paragraph.hasPrefix("<") {
                result.append("<p>\(paragraph)</p>")
            } else {
                result.append(paragraph)
            }
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