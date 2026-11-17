import Foundation
import XCTest
@testable import OTPCore

final class TimelineScheduleTests: XCTestCase {
    func testUsesAccountAlgorithmAndDigits() throws {
        let secret = Data("12345678901234567890123456789012".utf8)
        let entries = try TimelineSchedule.entries(secret: secret, now: Date(timeIntervalSince1970: 118), count: 2, period: 60, digits: 8, algorithm: .sha256)
        XCTAssertEqual(entries.first?.code, "46119246")
    }

    func testStartsNowThenUsesExactBoundariesAndExpires() throws {
        let secret = Data("12345678901234567890".utf8)
        let now = Date(timeIntervalSince1970: 59.7)
        let entries = try TimelineSchedule.entries(secret: secret, now: now, count: 3)
        XCTAssertEqual(entries.count, 4)
        guard entries.count == 4 else { return }
        XCTAssertEqual(entries[0].date, now)
        XCTAssertEqual(entries.dropFirst().map { $0.date.timeIntervalSince1970 }, [60, 90, 120])
        XCTAssertEqual(entries.map { $0.validUntil.timeIntervalSince1970 }, [60, 90, 120, 120])
        XCTAssertEqual(entries[0].code, "287082")
        XCTAssertEqual(entries[1].code, try TOTPEngine.code(secret: secret, timestamp: 60))
        XCTAssertNil(entries.last?.code)
        XCTAssertTrue(entries.allSatisfy { $0.generatedAt == now })
    }

    func testRejectsUnboundedAndInvalidCount() {
        let secret = Data("12345678901234567890".utf8)
        for count in [0, -1, 721] {
            XCTAssertThrowsError(try TimelineSchedule.entries(secret: secret, now: Date(), count: count))
        }
    }
}
