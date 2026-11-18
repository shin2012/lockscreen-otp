import SwiftUI
import WidgetKit

struct OTPDisplayEntry {
    let date: Date
    let validUntil: Date
    let period: Int
    let code: String?
    let label: String
    let showWhenLocked: Bool
    var showName: Bool = true
    var showTime: Bool = true
    var hideInAOD: Bool = true
    let message: String?

    /// Whole current period, so the ring is partly drained when an entry starts mid-period.
    var window: ClosedRange<Date>? {
        guard code != nil, period > 0 else { return nil }
        let start = validUntil.addingTimeInterval(-Double(period))
        return start < validUntil ? start...validUntil : nil
    }
}

struct CircularOTPView: View {
    @Environment(\.isLuminanceReduced) private var aod
    let entry: OTPDisplayEntry
    private var hidden: Bool { aod && entry.hideInAOD }
    var body: some View {
        ZStack {
            if entry.showTime, !hidden, let window = entry.window {
                ProgressView(timerInterval: window, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                    .progressViewStyle(.circular)
            } else {
                AccessoryWidgetBackground()
            }
            content.padding(entry.showTime ? 5 : 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.label) \(hidden ? "가림" : entry.code ?? entry.message ?? "코드 없음")")
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            if entry.showName {
                Text(entry.label)
                    .font(.system(size: 8, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)
            }
            Group {
                if hidden {
                    Image(systemName: "lock.fill")
                } else if let code = entry.code {
                    Text(String(code.prefix(code.count / 2)))
                    Text(String(code.suffix(code.count - code.count / 2)))
                } else {
                    Image(systemName: "lock.fill")
                    Text(entry.message == "기간 만료" ? "만료" : "확인").font(.system(size: 9))
                }
            }
            .font(.system(size: entry.showName || entry.showTime ? 15 : 20, weight: .semibold, design: .rounded).monospacedDigit())
            .minimumScaleFactor(0.6)
            .privacySensitive(!entry.showWhenLocked)
        }
    }
}

struct InlineOTPView: View {
    @Environment(\.isLuminanceReduced) private var aod
    let entry: OTPDisplayEntry
    var body: some View {
        let name = entry.showName ? String(entry.label.prefix(8)) + " " : ""
        if aod && entry.hideInAOD {
            Text("\(Image(systemName: "lock.fill")) \(name)")
        } else if let code = entry.code {
            if entry.showTime, let window = entry.window {
                (Text("\(name)\(code) · ") + Text(timerInterval: window, countsDown: true, showsHours: false))
                    .monospacedDigit()
                    .privacySensitive(!entry.showWhenLocked)
            } else {
                Text("\(name)\(code)").monospacedDigit().privacySensitive(!entry.showWhenLocked)
            }
        } else {
            Text("\(name)\(entry.message ?? "확인 필요")")
        }
    }
}
