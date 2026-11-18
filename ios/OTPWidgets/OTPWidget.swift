import WidgetKit
import SwiftUI

struct OTPEntry: TimelineEntry {
    let date: Date
    let display: OTPDisplayEntry
}

struct OTPProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OTPEntry { unavailable("미리보기", demo: true, showName: true) }
    func snapshot(for configuration: OTPWidgetIntent, in context: Context) async -> OTPEntry {
        if context.isPreview { return unavailable("시험", demo: true, showName: configuration.showName) }
        return makeTimeline(configuration).entries.first ?? unavailable("앱 확인", showName: configuration.showName)
    }
    func timeline(for configuration: OTPWidgetIntent, in context: Context) async -> Timeline<OTPEntry> {
        makeTimeline(configuration)
    }

    private func unavailable(_ message: String, demo: Bool = false, showName: Bool) -> OTPEntry {
        let now = Date()
        return OTPEntry(date: now, display: OTPDisplayEntry(date: now, validUntil: now, code: nil, label: demo ? "시험" : "OTP", generatedAt: now, demo: demo, showWhenLocked: false, showName: showName, message: message))
    }
    private func makeTimeline(_ configuration: OTPWidgetIntent) -> Timeline<OTPEntry> {
        let now = Date()
        let showName = configuration.showName
        let retry = TimelineReloadPolicy.after(now.addingTimeInterval(900))
        do {
            let vault = try KeychainVault.load()
            let account: OTPAccount
            switch WidgetAccountResolver.resolve(accounts: vault.accounts, selectedID: vault.selectedID, demoMode: vault.demoMode, widgetsEnabled: vault.widgetsEnabled, requestedID: configuration.account?.id) {
            case .account(let value): account = value
            case .notAllowed: return Timeline(entries: [unavailable("앱에서 허용", showName: showName)], policy: retry)
            case .missing: return Timeline(entries: [unavailable("계정 선택", showName: showName)], policy: retry)
            }
            let demo = account.id == OTPAccount.demo.id
            let values = try TimelineSchedule.entries(secret: account.secret, now: now, count: vault.entryCount, period: account.period, digits: account.digits, algorithm: account.algorithm)
            let entries = values.map { value in
                OTPEntry(date: value.date, display: OTPDisplayEntry(date: value.date, validUntil: value.validUntil, code: value.code, label: account.label, generatedAt: value.generatedAt, demo: demo, showWhenLocked: vault.showWhenLocked, showName: showName, message: value.code == nil ? "기간 만료" : nil))
            }
            let end = values.last!.date
            return Timeline(entries: entries, policy: .after(end.addingTimeInterval(-min(300, end.timeIntervalSince(now) / 2))))
        } catch {
            return Timeline(entries: [unavailable("잠금 해제", showName: showName)], policy: retry)
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
            .description("위젯을 눌러 계정과 이름 표시를 고를 수 있습니다. 자동 갱신은 실험 기능입니다.")
            .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}
