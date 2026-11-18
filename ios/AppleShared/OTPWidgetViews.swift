import SwiftUI

struct OTPDisplayEntry {
    let date: Date
    let validUntil: Date
    let code: String?
    let label: String
    let generatedAt: Date
    let demo: Bool
    let showWhenLocked: Bool
    var showName: Bool = true
    let message: String?
}

struct CircularOTPView: View {
    let entry: OTPDisplayEntry
    var body: some View {
        VStack(spacing: 0) {
            if entry.showName {
                Text(entry.demo ? "시험" : entry.label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 6)
            }
            Group {
                if let code = entry.code {
                    Text(String(code.prefix(code.count / 2)))
                    Text(String(code.suffix(code.count - code.count / 2)))
                } else {
                    Image(systemName: "lock.fill")
                    Text(entry.message == "기간 만료" ? "만료" : "확인")
                        .font(.system(size: 10))
                }
            }
            .font(.system(size: entry.showName ? 16 : 20, weight: .semibold, design: .rounded).monospacedDigit())
            .privacySensitive(!entry.demo && !entry.showWhenLocked)
        }
        .minimumScaleFactor(0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.label) \(entry.code ?? entry.message ?? "코드 없음")")
    }
}

struct InlineOTPView: View {
    let entry: OTPDisplayEntry
    var body: some View {
        let value = entry.code ?? entry.message ?? "확인 필요"
        let name = entry.demo ? "시험" : String(entry.label.prefix(8))
        Text(entry.showName ? "\(name) \(value)" : value)
            .monospacedDigit()
            .privacySensitive(!entry.demo && !entry.showWhenLocked)
    }
}
