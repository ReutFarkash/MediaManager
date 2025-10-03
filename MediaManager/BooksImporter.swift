import Foundation

struct BookInfo {
    let title: String
    let author: String
}

class BooksImporter {
    // Making this function async for better integration with Swift Concurrency
    static func fetchBooks() async -> [BookInfo] {
        // AppleScript execution should be run in a Task
        return await Task.detached(priority: .userInitiated) {
            let appleScript = """
            tell application "Books"
                set output to ""
                repeat with b in books
                    set output to output & (name of b as string) & "||" & (author of b as string) & ";;"
                end repeat
                return output
            end tell
            """
            
            // Escape double quotes correctly for osascript command line
            let scriptArgument = appleScript.replacingOccurrences(of: "\"", with: "\\\"")
            let script = "osascript -e \"\(scriptArgument)\""
            
            let task = Process()
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe // Capture stderr for debugging
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", script]
            
            do {
                try task.run()
                task.waitUntilExit() // Wait for the script to finish
            } catch {
                print("Failed to run AppleScript process: \(error.localizedDescription)")
                // Also print stderr if available for more context
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                if !errorData.isEmpty, let errorOutput = String(data: errorData, encoding: .utf8) {
                    print("AppleScript stderr: \(errorOutput)")
                }
                return []
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("Failed to decode AppleScript output to String.")
                return []
            }
            return await parseBooks(from: output)
        }.value
    }

    @MainActor
    static func parseBooks(from output: String) -> [BookInfo] {
        output.split(separator: ";;").compactMap { entry in
            let fields = entry.split(separator: "||", omittingEmptySubsequences: false)
            guard fields.count == 2 else {
                if !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("Warning: Skipping malformed book entry: '\(entry)'")
                }
                return nil
            }
            let title = String(fields[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let author = String(fields[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // A book should at least have a title
            if title.isEmpty {
                print("Warning: Skipping book entry with empty title: '\(entry)'")
                return nil
            }
            return BookInfo(title: title, author: author)
        }
    }
}
