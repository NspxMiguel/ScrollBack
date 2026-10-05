import Foundation

enum Log {
    private static let fileURL = FileManager.default
        .urls(for: .libraryDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Logs/ScrollBack.log")

    static func write(_ message: String) {
        append("[info] \(message)")
    }

    static func error(_ message: String) {
        append("[error] \(message)")
    }

    private static var reported = Set<String>()

    /// Same as `error`, but each message is written once per launch. Used on
    /// paths the permission retry hits every two seconds.
    static func errorOnce(_ message: String) {
        guard reported.insert(message).inserted else { return }
        error(message)
    }

    private static func append(_ line: String) {
        let stamped = "\(ISO8601DateFormatter().string(from: Date())) \(line)\n"
        FileHandle.standardError.write(Data(stamped.utf8))

        guard let data = stamped.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: fileURL)
        }
    }
}
