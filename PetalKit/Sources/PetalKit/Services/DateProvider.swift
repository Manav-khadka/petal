import Foundation

public protocol DateProvider: Sendable {
    var now: Date { get }
}

public struct SystemDateProvider: DateProvider {
    public init() {}
    public var now: Date {
        Date()
    }
}

public struct MockDateProvider: DateProvider {
    public var fixedDate: Date

    public init(fixedDate: Date) {
        self.fixedDate = fixedDate
    }

    public var now: Date {
        fixedDate
    }
}
