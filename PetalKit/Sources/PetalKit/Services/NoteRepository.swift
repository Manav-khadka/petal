import Foundation

public protocol NoteRepository: Sendable {
    func fetchAll() async throws -> [Note]
    func fetch(by id: Note.ID) async throws -> Note?
    func save(_ note: Note) async throws
    func delete(_ id: Note.ID) async throws
    func search(query: String) async throws -> [Note]
}
