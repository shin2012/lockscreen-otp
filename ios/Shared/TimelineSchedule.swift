import Foundation

public struct ScheduledOTP: Sendable {
    public let date: Date
    public let validUntil: Date
    public let code: String?
    public let generatedAt: Date
}

public enum TimelineSchedule {
    public static func entries(secret: Data, now: Date, count: Int = 120, period: Int = 30, digits: Int = 6, algorithm: OTPAlgorithm = .sha1) throws -> [ScheduledOTP] {
        guard (1...720).contains(count) else { throw OTPError.invalidCount }
        _ = try TOTPEngine.code(secret: secret, timestamp: now.timeIntervalSince1970, digits: digits, period: period, algorithm: algorithm)
        let start = floor(now.timeIntervalSince1970 / Double(period)) * Double(period)
        var result: [ScheduledOTP] = []
        for index in 0..<count {
            let boundary = start + Double(index * period)
            let date = index == 0 ? now : Date(timeIntervalSince1970: boundary)
            let until = Date(timeIntervalSince1970: boundary + Double(period))
            let code = try TOTPEngine.code(secret: secret, timestamp: boundary, digits: digits, period: period, algorithm: algorithm)
            result.append(ScheduledOTP(date: date, validUntil: until, code: code, generatedAt: now))
        }
        let end = Date(timeIntervalSince1970: start + Double(count * period))
        result.append(ScheduledOTP(date: end, validUntil: end, code: nil, generatedAt: now))
        return result
    }
}
