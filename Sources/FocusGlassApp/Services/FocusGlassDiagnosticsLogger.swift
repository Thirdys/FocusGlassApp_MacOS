import Foundation

enum FocusGlassLogLevel: String, Codable {
    case info
    case warning
    case error
}

struct FocusGlassLogEntry: Codable, Identifiable {
    var id: UUID
    var createdAt: Date
    var expiresAt: Date
    var level: FocusGlassLogLevel
    var subsystem: String
    var code: String
    var message: String
    var details: [String: String]
    var resolutionHint: String
    var appVersion: String
    var buildVersion: String
}

@MainActor
final class FocusGlassDiagnosticsLogger {
    static let shared = FocusGlassDiagnosticsLogger()

    private let retention: TimeInterval = 7 * 24 * 60 * 60
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileURL: URL

    private init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = baseURL.appendingPathComponent("FocusGlass/Logs", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("diagnostics.jsonl")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        pruneExpiredEntries()
    }

    func log(
        _ level: FocusGlassLogLevel,
        subsystem: String,
        code: String,
        message: String,
        details: [String: String] = [:],
        resolutionHint: String
    ) {
        pruneExpiredEntries()

        let now = Date()
        let entry = FocusGlassLogEntry(
            id: UUID(),
            createdAt: now,
            expiresAt: now.addingTimeInterval(retention),
            level: level,
            subsystem: subsystem,
            code: code,
            message: message,
            details: details,
            resolutionHint: resolutionHint,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev",
            buildVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "dev"
        )

        guard let data = try? encoder.encode(entry),
              let line = String(data: data, encoding: .utf8) else { return }

        if FileManager.default.fileExists(atPath: fileURL.path),
           let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: Data("\n\(line)".utf8))
        } else {
            try? Data(line.utf8).write(to: fileURL, options: [.atomic])
        }
    }

    func recentEntries() -> [FocusGlassLogEntry] {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        return text
            .split(separator: "\n")
            .compactMap { line in
                try? decoder.decode(FocusGlassLogEntry.self, from: Data(line.utf8))
            }
            .filter { $0.expiresAt > Date() }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func pruneExpiredEntries() {
        let entries = recentEntries()
        guard !entries.isEmpty else {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
            return
        }

        let lines = entries
            .reversed()
            .compactMap { entry -> String? in
                guard let data = try? encoder.encode(entry) else { return nil }
                return String(data: data, encoding: .utf8)
            }
            .joined(separator: "\n")
        try? Data(lines.utf8).write(to: fileURL, options: [.atomic])
    }
}
