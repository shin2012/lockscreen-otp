import SwiftUI

struct OTPDisplayEntry {
    let date: Date
    let validUntil: Date
    let code: String?
    let label: String
    let generatedAt: Date
    let demo: Bool
    let showWhenLocked: Bool
    let message: String?
}

struct CircularOTPView: View {
    let entry: OTPDisplayEntry
    var body: some View {
        VStack(spacing: 0) {
            if let code = entry.code {
                Text(String(code.prefix(code.count / 2)))
                Text(String(code.suffix(code.count - code.count / 2)))
            } else {
                Image(systemName: "lock.fill")
                Text(entry.message == "기간 만료" ? "만료" : "확인")
                    .font(.system(size: 10))
            }
        }
        .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
        .minimumScaleFactor(0.6)
        .accessibilityLabel("\(entry.label) \(entry.code ?? entry.message ?? "코드 없음")")
        .privacySensitive(!entry.demo && !entry.showWhenLocked)
    }
}

struct InlineOTPView: View {
    let entry: OTPDisplayEntry
    var body: some View {
        Text("\(entry.demo ? "시험" : String(entry.label.prefix(8))) \(entry.code ?? entry.message ?? "확인 필요")")
            .monospacedDigit()
            .privacySensitive(!entry.demo && !entry.showWhenLocked)
    }
}
