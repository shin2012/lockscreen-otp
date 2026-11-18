#if os(macOS)
import SwiftUI
import WidgetKit

/// Desktop / Notification Center widget on macOS. Same entry data as the lock-screen widget.
struct MacOTPWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OTPDisplayEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill").foregroundStyle(.tint)
                if entry.showName {
                    Text(entry.label).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
            if let code = entry.code {
                Text(spaced(code))
                    .font(.system(size: family == .systemSmall ? 32 : 44, weight: .semibold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .privacySensitive()
            } else {
                Label(entry.message ?? "확인 필요", systemImage: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let window = entry.window {
                switch entry.ring {
                case .seconds:
                    HStack(spacing: 2) {
                        Text(timerInterval: window, countsDown: true, showsHours: false).monospacedDigit()
                        Text("초 남음")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                case .none:
                    EmptyView()
                default:
                    ProgressView(timerInterval: window, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                        .progressViewStyle(.linear)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.label) \(entry.code ?? entry.message ?? "코드 없음")")
    }
    private func spaced(_ code: String) -> String {
        guard code.count >= 6 else { return code }
        let half = code.count / 2
        return "\(code.prefix(half)) \(code.suffix(code.count - half))"
    }
}
#endif
