import Foundation

public actor FileNoteRepository: NoteRepository {
    private let directoryURL: URL
    private let fileManager = FileManager.default

    public init(directoryURL: URL? = nil) {
        if let dir = directoryURL {
            self.directoryURL = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directoryURL = appSupport.appendingPathComponent("Petal/Notes", isDirectory: true)
        }
        try? fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    private func fileURL(for id: Note.ID) -> URL {
        directoryURL.appendingPathComponent("\(id.uuidString).json")
    }

    public func fetchAll() async throws -> [Note] {
        guard let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }
        var notes: [Note] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let note = try? decoder.decode(Note.self, from: data) {
                notes.append(note)
            }
        }
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func fetch(by id: Note.ID) async throws -> Note? {
        let file = fileURL(for: id)
        guard let data = try? Data(contentsOf: file) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Note.self, from: data)
    }

    public func save(_ note: Note) async throws {
        let file = fileURL(for: note.id)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(note)
        try data.write(to: file, options: [.atomic])
    }

    public func delete(_ id: Note.ID) async throws {
        let file = fileURL(for: id)
        if fileManager.fileExists(atPath: file.path) {
            try fileManager.removeItem(at: file)
        }
    }

    public func search(query: String) async throws -> [Note] {
        let all = try await fetchAll()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let lower = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(lower) ||
                $0.body.lowercased().contains(lower) ||
                $0.folder.lowercased().contains(lower) ||
                $0.checklist.contains { $0.text.lowercased().contains(lower) }
        }
    }
}
