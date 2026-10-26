import Foundation

public actor InMemoryNoteRepository: NoteRepository {
    private var storage: [Note.ID: Note] = [:]

    public init(initialNotes: [Note] = []) {
        for note in initialNotes {
            storage[note.id] = note
        }
    }

    public func fetchAll() async throws -> [Note] {
        Array(storage.values).sorted { $0.updatedAt > $1.updatedAt }
    }

    public func fetch(by id: Note.ID) async throws -> Note? {
        storage[id]
    }

    public func save(_ note: Note) async throws {
        storage[note.id] = note
    }

    public func delete(_ id: Note.ID) async throws {
        storage.removeValue(forKey: id)
    }

    public func search(query: String) async throws -> [Note] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return try await fetchAll()
        }
        let lower = query.lowercased()
        return storage.values.filter {
            $0.title.lowercased().contains(lower) ||
                $0.body.lowercased().contains(lower) ||
                $0.checklist.contains { $0.text.lowercased().contains(lower) }
        }.sorted { $0.updatedAt > $1.updatedAt }
    }
}
