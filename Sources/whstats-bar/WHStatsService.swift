import Foundation

enum WHStatsServiceError: LocalizedError {
    case invalidUTF8
    case processFailed(code: Int32, message: String)
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            return "Unable to decode command output as UTF-8."
        case let .processFailed(code, message):
            return "whstats failed (\(code)): \(message)"
        case .invalidJSON:
            return "Command output is not valid JSON."
        }
    }
}

struct WHStatsService {
    func fetchStats() async throws -> WHStatsResponse {
        let output = try await runWhstatsCommand()
        let jsonData = try sanitizeJSONData(from: output)
        let decoder = JSONDecoder()
        return try decoder.decode(WHStatsResponse.self, from: jsonData)
    }

    private func runWhstatsCommand() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            // Run through the user's login shell so whstats sees the same environment as terminal runs.
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lic", "bun x whstats --json"]
            process.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { proc in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let outputString = String(data: outputData, encoding: .utf8)
                let errorString = String(data: errorData, encoding: .utf8) ?? ""

                guard let outputString else {
                    continuation.resume(throwing: WHStatsServiceError.invalidUTF8)
                    return
                }

                if proc.terminationStatus == 0 {
                    continuation.resume(returning: outputString)
                } else {
                    let message = errorString.isEmpty ? outputString : errorString
                    continuation.resume(
                        throwing: WHStatsServiceError.processFailed(
                            code: proc.terminationStatus,
                            message: message.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func sanitizeJSONData(from output: String) throws -> Data {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") else {
            throw WHStatsServiceError.invalidJSON
        }

        let jsonSubstring = trimmed[start...end]
        guard let data = String(jsonSubstring).data(using: .utf8) else {
            throw WHStatsServiceError.invalidUTF8
        }

        return data
    }
}
