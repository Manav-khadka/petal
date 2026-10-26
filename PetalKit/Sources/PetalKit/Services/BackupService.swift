import Foundation

public enum BackupStatus: Codable, Sendable, Equatable {
    case backedUp(Date)
    case syncing(Int)
    case offline
    case needsSignIn
    case driveFull

    public var message: String {
        switch self {
        case let .backedUp(date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Backed up \(formatter.localizedString(for: date, relativeTo: Date()))"
        case let .syncing(count):
            return "Backing up \(count) notes…"
        case .offline:
            return "Waiting for internet; changes are queued"
        case .needsSignIn:
            return "Reconnect Google Drive"
        case .driveFull:
            return "Drive is full; free space to continue"
        }
    }
}

public struct BackupSnapshot: Codable, Sendable, Identifiable {
    public let id: String
    public let date: Date
    public let noteCount: Int
    public let notes: [Note]

    public init(id: String = UUID().uuidString, date: Date = Date(), noteCount: Int, notes: [Note] = []) {
        self.id = id
        self.date = date
        self.noteCount = noteCount
        self.notes = notes
    }
}

public protocol BackupService: Sendable {
    var status: BackupStatus { get async }
    func backup(notes: [Note]) async throws -> BackupSnapshot
    func listSnapshots() async throws -> [BackupSnapshot]
    func restore(snapshotID: String) async throws -> [Note]
    func disconnect() async throws
}
