import Foundation

public actor DriveSyncManager: BackupService {
    private var currentStatus: BackupStatus = .backedUp(Date())
    private let localDirectory: URL
    private let snapshotsDirectory: URL
    private let fileManager = FileManager.default

    public init(baseDirectory: URL? = nil) {
        if let base = baseDirectory {
            localDirectory = base.appendingPathComponent("DriveBackup", isDirectory: true)
            snapshotsDirectory = base.appendingPathComponent("Snapshots", isDirectory: true)
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            localDirectory = appSupport.appendingPathComponent("Petal/DriveBackup", isDirectory: true)
            snapshotsDirectory = appSupport.appendingPathComponent("Petal/Snapshots", isDirectory: true)
        }
        try? fileManager.createDirectory(at: localDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: snapshotsDirectory, withIntermediateDirectories: true)
    }

    public var status: BackupStatus {
        currentStatus
    }

    public func setStatus(_ newStatus: BackupStatus) {
        currentStatus = newStatus
    }

    public func backup(notes: [Note]) async throws -> BackupSnapshot {
        currentStatus = .syncing(notes.count)

        let snapshot = BackupSnapshot(
            id: UUID().uuidString,
            date: Date(),
            noteCount: notes.count,
            notes: notes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let snapshotURL = snapshotsDirectory.appendingPathComponent("snapshot-\(snapshot.id).json")
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)

        // Also write latest mirror files
        for note in notes {
            let noteURL = localDirectory.appendingPathComponent("\(note.id.uuidString).json")
            if let noteData = try? encoder.encode(note) {
                try? noteData.write(to: noteURL, options: .atomic)
            }
        }

        currentStatus = .backedUp(snapshot.date)
        return snapshot
    }

    public func listSnapshots() async throws -> [BackupSnapshot] {
        guard let files = try? fileManager.contentsOfDirectory(at: snapshotsDirectory, includingPropertiesForKeys: nil)
        else {
            return []
        }
        var snapshots: [BackupSnapshot] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let snap = try? decoder.decode(BackupSnapshot.self, from: data) {
                snapshots.append(snap)
            }
        }
        return snapshots.sorted { $0.date > $1.date }
    }

    public func restore(snapshotID: String) async throws -> [Note] {
        let snapshotURL = snapshotsDirectory.appendingPathComponent("snapshot-\(snapshotID).json")
        guard let data = try? Data(contentsOf: snapshotURL) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snap = try decoder.decode(BackupSnapshot.self, from: data)
        return snap.notes.map { note in
            var copy = note
            copy.title = "\(note.title) (restored)"
            return copy
        }
    }

    public func disconnect() async throws {
        currentStatus = .needsSignIn
    }
}
