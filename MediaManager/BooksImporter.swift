import Foundation

struct BookInfo {
    let title: String
    let author: String
}

class BooksImporter {
    static func fetchBooks() -> [BookInfo] {
        let appleScript = """
        tell application \"Books\"
            set output to \"\"
            repeat with b in books
                set output to output & (name of b as string) & \"||\" & (author of b as string) & \";;\"
            end repeat
            return output
        end tell
        """
        let script = "osascript -e \"\(appleScript.replacingOccurrences(of: "\"", with: "\\\"") )\""
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        do {
            try task.run()
        } catch {
            print("Failed to run AppleScript: \(error)")
            return []
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        return parseBooks(from: output)
    }

    private static func parseBooks(from output: String) -> [BookInfo] {
        output.split(separator: ";;").compactMap { entry in
            let fields = entry.split(separator: "||", omittingEmptySubsequences: false)
            guard fields.count == 2 else { return nil }
            let title = String(fields[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let author = String(fields[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty { return nil }
            return BookInfo(title: title, author: author)
        }
    }
}
