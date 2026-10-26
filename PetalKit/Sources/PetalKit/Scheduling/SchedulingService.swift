import Foundation

public struct SchedulingService: Sendable {
    public init() {}

    /// Parses natural text like "in 1 hr", "tomorrow 5pm", "tonight", "10m"
    public static func parseDate(text: String, referenceDate: Date = Date(), calendar: Calendar = .current) -> Date? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // "in X min/m/hr/h"
        if clean.hasPrefix("in ") {
            let rest = clean.dropFirst(3).trimmingCharacters(in: .whitespaces)
            return parseRelativeOffset(rest, referenceDate: referenceDate)
        }

        // Direct "10m", "25 min", "1h"
        if let relative = parseRelativeOffset(clean, referenceDate: referenceDate) {
            return relative
        }

        // "tonight" -> today at 8:00 PM
        if clean == "tonight" {
            var comp = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            comp.hour = 20
            comp.minute = 0
            if let date = calendar.date(from: comp), date > referenceDate {
                return date
            }
            return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: comp)!)
        }

        // "tomorrow 9 am" or "tomorrow 5pm" or "tomorrow"
        if clean.hasPrefix("tomorrow") {
            let timePart = clean.dropFirst(8).trimmingCharacters(in: .whitespaces)
            guard let tomorrowBase = calendar.date(byAdding: .day, value: 1, to: referenceDate) else { return nil }
            if timePart.isEmpty {
                var comp = calendar.dateComponents([.year, .month, .day], from: tomorrowBase)
                comp.hour = 9
                comp.minute = 0
                return calendar.date(from: comp)
            }
            return parseTimeOfDay(timePart, on: tomorrowBase, calendar: calendar)
        }

        // Specific time today e.g. "5pm", "17:00", "9:30 am"
        if let todayTime = parseTimeOfDay(clean, on: referenceDate, calendar: calendar) {
            if todayTime > referenceDate {
                return todayTime
            } else {
                return calendar.date(byAdding: .day, value: 1, to: todayTime)
            }
        }

        return nil
    }

    private static func parseRelativeOffset(_ string: String, referenceDate: Date) -> Date? {
        let pattern = #"^(\d+)\s*(m|min|mins|minute|minutes|h|hr|hrs|hour|hours)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(string.startIndex ..< string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range),
              let numRange = Range(match.range(at: 1), in: string),
              let unitRange = Range(match.range(at: 2), in: string),
              let amount = Double(string[numRange]) else { return nil }

        let unit = String(string[unitRange]).lowercased()
        if unit.hasPrefix("h") {
            return referenceDate.addingTimeInterval(amount * 3600)
        } else {
            return referenceDate.addingTimeInterval(amount * 60)
        }
    }

    private static func parseTimeOfDay(_ string: String, on baseDate: Date, calendar: Calendar) -> Date? {
        let pattern = #"^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(string.startIndex ..< string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range),
              let hourRange = Range(match.range(at: 1), in: string),
              var hour = Int(string[hourRange]) else { return nil }

        var minute = 0
        if match.range(at: 2).location != NSNotFound,
           let minRange = Range(match.range(at: 2), in: string),
           let parsedMin = Int(string[minRange]) {
            minute = parsedMin
        }

        if match.range(at: 3).location != NSNotFound,
           let ampmRange = Range(match.range(at: 3), in: string) {
            let ampm = String(string[ampmRange]).lowercased()
            if ampm == "pm" && hour < 12 {
                hour += 12
            } else if ampm == "am" && hour == 12 {
                hour = 0
            }
        }

        var comp = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comp.hour = hour
        comp.minute = minute
        comp.second = 0
        return calendar.date(from: comp)
    }

    /// Parses quick-open command: e.g. "timer 10m", "remind Buy groceries 5pm", "new Project ideas"
    public static func parseCommand(_ input: String) -> ParsedCommand {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if lower == "new" {
            return .newNote(title: "")
        }
        if lower.hasPrefix("new ") {
            let title = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            return .newNote(title: title)
        }

        if lower.hasPrefix("timer ") {
            let timeStr = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            let digits = timeStr.filter { $0.isNumber }
            if let minutes = Int(digits), minutes > 0 {
                return .startTimer(minutes: minutes)
            }
        }

        if lower.hasPrefix("remind ") {
            let rest = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            // Look for time at end e.g. "Buy milk tomorrow 5pm" or "call mom in 10m"
            let words = rest.components(separatedBy: .whitespaces)
            for i in stride(from: max(1, words.count - 3), through: words.count - 1, by: 1) {
                let timeCandidate = words[i...].joined(separator: " ")
                if let targetDate = parseDate(text: timeCandidate) {
                    let title = words[..<i].joined(separator: " ")
                    return .createReminder(title: title.isEmpty ? "Reminder" : title, date: targetDate)
                }
            }
            return .createReminder(title: rest, date: Date().addingTimeInterval(3600))
        }

        return .search(query: trimmed)
    }
}

public enum ParsedCommand: Sendable, Equatable {
    case newNote(title: String)
    case startTimer(minutes: Int)
    case createReminder(title: String, date: Date)
    case search(query: String)
}
