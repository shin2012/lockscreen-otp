import SwiftUI
import WidgetKit

/// How the remaining time is shown inside the circular widget.
/// Every style is drawn by the system from one date range, so none needs extra timeline entries.
enum OTPRingStyle: String, Codable, Sendable, CaseIterable {
    case bar, ring, seconds, none
}

struct OTPDisplayEntry {
    let date: Date
    let validUntil: Date
    let period: Int
    let code: String?
    let label: String
    let showWhenLocked: Bool
    var showName: Bool = true
    var ring: OTPRingStyle = .bar
    var showTime: Bool { ring != .none }
    var hideInAOD: Bool = true
    let message: String?

    /// Whole current period, so the indicator is partly drained when an entry starts mid-period.
    var window: ClosedRange<Date>? {
        guard code != nil, period > 0 else { return nil }
        let start = validUntil.addingTimeInterval(-Double(period))
        return start < validUntil ? start...validUntil : nil
    }
}

#if os(iOS)
struct CircularOTPView: View {
    @Environment(\.isLuminanceReduced) private var aod
    let entry: OTPDisplayEntry
    private var hidden: Bool { aod && entry.hideInAOD }
    private var window: ClosedRange<Date>? { hidden ? nil : entry.window }
    var body: some View {
        ZStack {
            if entry.ring == .ring, let window {
                ProgressView(timerInterval: window, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                    .progressViewStyle(.circular)
            } else {
                AccessoryWidgetBackground()
            }
            content
                .padding(.horizontal, entry.ring == .ring ? 8 : 6)
                .padding(.vertical, 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.label) \(hidden ? "가림" : entry.code ?? entry.message ?? "코드 없음")")
    }

    private var codeSize: CGFloat {
        let extras = (entry.showName ? 1 : 0) + (entry.showTime && entry.ring != .ring ? 1 : 0)
        if entry.ring == .ring { return entry.showName ? 14 : 17 }
        return [19, 17, 15][extras]
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 1) {
            if entry.showName {
                Text(entry.label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 40)
                    .opacity(0.85)
            }
            VStack(spacing: -2) {
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
            .font(.system(size: codeSize, weight: .semibold, design: .rounded).monospacedDigit())
            .minimumScaleFactor(0.6)
            .privacySensitive(!entry.showWhenLocked)
            if let window {
                switch entry.ring {
                case .bar:
                    ProgressView(timerInterval: window, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                        .progressViewStyle(.linear)
                        .frame(width: 28)
                        .scaleEffect(x: 1, y: 0.6)
                        .padding(.top, 2)
                case .seconds:
                    Text(timerInterval: window, countsDown: true, showsHours: false)
                        .font(.system(size: 9, weight: .medium).monospacedDigit())
                        .multilineTextAlignment(.center)
                        .frame(width: 30)
                        .opacity(0.85)
                default:
                    EmptyView()
                }
            }
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
#endif
