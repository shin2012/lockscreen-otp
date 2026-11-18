import WidgetKit
import SwiftUI

struct OTPEntry: TimelineEntry {
    let date: Date
    let display: OTPDisplayEntry
}

struct OTPProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OTPEntry { sample() }
    func snapshot(for configuration: OTPWidgetIntent, in context: Context) async -> OTPEntry {
        if context.isPreview { return sample(configuration) }
        return makeTimeline(configuration).entries.first ?? unavailable("앱 확인", configuration)
    }
    func timeline(for configuration: OTPWidgetIntent, in context: Context) async -> Timeline<OTPEntry> {
        makeTimeline(configuration)
    }

    /// Gallery/placeholder look only; a fixed number, never derived from a key.
    private func sample(_ configuration: OTPWidgetIntent? = nil) -> OTPEntry {
        let now = Date()
        let until = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 30) + 1) * 30)
        return OTPEntry(date: now, display: OTPDisplayEntry(date: now, validUntil: until, period: 30, code: "123456", label: "계정", showWhenLocked: true, showName: configuration?.showName ?? true, ring: configuration?.ring ?? .bar, hideInAOD: configuration?.hideInAOD ?? true, message: nil))
    }
    private func unavailable(_ message: String, _ configuration: OTPWidgetIntent) -> OTPEntry {
        let now = Date()
        return OTPEntry(date: now, display: OTPDisplayEntry(date: now, validUntil: now, period: 30, code: nil, label: "OTP", showWhenLocked: false, showName: configuration.showName, ring: .none, hideInAOD: configuration.hideInAOD, message: message))
    }
    private func makeTimeline(_ configuration: OTPWidgetIntent) -> Timeline<OTPEntry> {
        let now = Date()
        let retry = TimelineReloadPolicy.after(now.addingTimeInterval(900))
        do {
            let vault = try KeychainVault.load()
            let account: OTPAccount
            switch WidgetAccountResolver.resolve(accounts: vault.accounts, selectedID: vault.selectedID, widgetsEnabled: vault.widgetsEnabled, requestedID: configuration.account?.id) {
            case .account(let value): account = value
            case .notAllowed: return Timeline(entries: [unavailable("앱에서 허용", configuration)], policy: retry)
            case .missing: return Timeline(entries: [unavailable("계정 추가", configuration)], policy: retry)
            }
            let values = try TimelineSchedule.entries(secret: account.secret, now: now, count: vault.entryCount, period: account.period, digits: account.digits, algorithm: account.algorithm)
            let entries = values.map { value in
                OTPEntry(date: value.date, display: OTPDisplayEntry(date: value.date, validUntil: value.validUntil, period: account.period, code: value.code, label: account.label, showWhenLocked: vault.showWhenLocked, showName: configuration.showName, ring: configuration.ring, hideInAOD: configuration.hideInAOD, message: value.code == nil ? "기간 만료" : nil))
            }
            let end = values.last!.date
            return Timeline(entries: entries, policy: .after(end.addingTimeInterval(-min(300, end.timeIntervalSince(now) / 2))))
        } catch {
            return Timeline(entries: [unavailable("잠금 해제", configuration)], policy: retry)
        }
    }
}

struct OTPWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OTPEntry
    var body: some View {
        Group {
            if family == .accessoryInline { InlineOTPView(entry: entry.display) }
            else { CircularOTPView(entry: entry.display) }
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(URL(string: "lockscreenotp://open"))
    }
}

@main
struct OTPWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockscreenOTP", intent: OTPWidgetIntent.self, provider: OTPProvider()) { entry in OTPWidgetView(entry: entry) }
            .configurationDisplayName("잠금 OTP")
            .description("위젯을 눌러 계정, 이름·남은 시간 표시, 상시 표시 화면 동작을 고를 수 있습니다.")
            .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}
