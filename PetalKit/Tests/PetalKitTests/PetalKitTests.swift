@testable import PetalKit
import XCTest

final class PetalKitTests: XCTestCase {
    func testNoteColorContrastAndNormalization() {
        let butter = NoteColor.butter
        XCTAssertEqual(butter.hex, "#FFF3B0")
        XCTAssertTrue(butter.requiresDarkText)

        let darkHex = NoteColor.normalize(hex: "000000")
        let darkColor = NoteColor(hex: darkHex)
        XCTAssertFalse(darkColor.requiresDarkText)

        let softened = butter.darkThemeHex
        XCTAssertTrue(softened.hasPrefix("#"))
    }

    func testTimerSessionCalculations() {
        let now = Date()
        let end = now.addingTimeInterval(25 * 60)
        var timer = TimerSession(durationMinutes: 25, endDate: end)

        XCTAssertTrue(timer.isRunning)
        XCTAssertFalse(timer.isFinished(at: now))
        XCTAssertEqual(timer.formattedRemaining(at: now), "25:00")

        let halfway = now.addingTimeInterval(12.5 * 60)
        let progress = timer.progress(at: halfway)
        XCTAssertEqual(progress, 0.5, accuracy: 0.05)

        let finishedTime = now.addingTimeInterval(26 * 60)
        XCTAssertTrue(timer.isFinished(at: finishedTime))

        // Paused timer
        timer.isPaused = true
        timer.remainingSecondsWhenPaused = 300
        XCTAssertEqual(timer.formattedRemaining(at: now), "05:00")
    }

    func testSchedulingNaturalLanguage() throws {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 26
        comp.hour = 12
        comp.minute = 0
        comp.second = 0
        let refDate = try XCTUnwrap(calendar.date(from: comp))

        // "in 15m"
        let in15 = SchedulingService.parseDate(text: "in 15m", referenceDate: refDate, calendar: calendar)
        XCTAssertNotNil(in15)
        XCTAssertEqual(in15?.timeIntervalSince(refDate), 15 * 60)

        // "in 2 hours"
        let in2h = SchedulingService.parseDate(text: "in 2 hours", referenceDate: refDate, calendar: calendar)
        XCTAssertNotNil(in2h)
        XCTAssertEqual(in2h?.timeIntervalSince(refDate), 2 * 3600)

        // "tonight"
        let tonight = SchedulingService.parseDate(text: "tonight", referenceDate: refDate, calendar: calendar)
        XCTAssertNotNil(tonight)
        let hour = try calendar.component(.hour, from: XCTUnwrap(tonight))
        XCTAssertEqual(hour, 20)

        // Command parsing
        let newCmd = SchedulingService.parseCommand("new Project Alpha")
        XCTAssertEqual(newCmd, .newNote(title: "Project Alpha"))

        let timerCmd = SchedulingService.parseCommand("timer 10m")
        XCTAssertEqual(timerCmd, .startTimer(minutes: 10))
    }

    func testAlarmNextFireDate() throws {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 26
        comp.hour = 8
        comp.minute = 0
        let refDate = try XCTUnwrap(calendar.date(from: comp))

        // Alarm at 9:00 AM today
        let alarm = Alarm(hour: 9, minute: 0)
        let nextDate = alarm.nextFireDate(from: refDate, calendar: calendar)
        XCTAssertNotNil(nextDate)
        XCTAssertEqual(try calendar.component(.hour, from: XCTUnwrap(nextDate)), 9)
        XCTAssertEqual(try calendar.component(.day, from: XCTUnwrap(nextDate)), 26)
    }

    func testInMemoryRepository() async throws {
        let repo = InMemoryNoteRepository()
        let note = Note(title: "Test Note", body: "Remember to breathe")
        try await repo.save(note)

        let fetched = try await repo.fetch(by: note.id)
        XCTAssertEqual(fetched?.title, "Test Note")

        let searchResults = try await repo.search(query: "breathe")
        XCTAssertEqual(searchResults.count, 1)

        try await repo.delete(note.id)
        let deleted = try await repo.fetch(by: note.id)
        XCTAssertNil(deleted)
    }

    func testDriveSyncManagerBackupAndRestore() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let syncManager = DriveSyncManager(baseDirectory: tempDir)

        let note = Note(title: "My Note", body: "Secret ideas")
        let snapshot = try await syncManager.backup(notes: [note])
        XCTAssertEqual(snapshot.noteCount, 1)

        let snapshots = try await syncManager.listSnapshots()
        XCTAssertEqual(snapshots.count, 1)

        let restored = try await syncManager.restore(snapshotID: snapshot.id)
        XCTAssertEqual(restored.first?.title, "My Note (restored)")
    }

    func testAgendaItemsFutureAndPast() {
        let now = Date()
        let pastDate = now.addingTimeInterval(-3600)
        let futureDate = now.addingTimeInterval(3600)

        let note1 = Note(
            title: "Task Note",
            checklist: [
                ChecklistItem(text: "Finish presentation", isDone: false),
                ChecklistItem(text: "Send recap email", isDone: true)
            ],
            reminder: Reminder(targetDate: futureDate)
        )

        let note2 = Note(
            title: "Past Reminder Note",
            reminder: Reminder(targetDate: pastDate, isCompleted: true)
        )

        let notes = [note1, note2]
        let allAgenda = notes.agendaItems()
        XCTAssertEqual(allAgenda.count, 4) // 2 reminders + 2 tasks

        let upcoming = notes.upcomingAgendaItems(from: now)
        XCTAssertTrue(upcoming.contains(where: { $0.title == "Task Note" && $0.type == .reminder }))
        XCTAssertTrue(upcoming.contains(where: { $0.title == "Finish presentation" && $0.type == .task }))

        let past = notes.pastAgendaItems(from: now)
        XCTAssertTrue(past.contains(where: { $0.title == "Past Reminder Note" }))
        XCTAssertTrue(past.contains(where: { $0.title == "Send recap email" }))
    }
}
