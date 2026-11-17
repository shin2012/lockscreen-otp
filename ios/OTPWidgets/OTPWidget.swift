import WidgetKit
import SwiftUI

struct OTPEntry: TimelineEntry {
    let date: Date
    let display: OTPDisplayEntry
}

struct OTPProvider: TimelineProvider {
    func placeholder(in context: Context) -> OTPEntry { unavailable("미리보기", demo: true) }
    func getSnapshot(in context: Context, completion: @escaping (OTPEntry) -> Void) {
        if context.isPreview { completion(unavailable("시험", demo: true)); return }
        completion(makeTimeline().entries.first ?? unavailable("앱 확인"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<OTPEntry>) -> Void) { completion(makeTimeline()) }

    private func unavailable(_ message: String, demo: Bool = false) -> OTPEntry {
        let now = Date()
        return OTPEntry(date: now, display: OTPDisplayEntry(date: now, validUntil: now, code: nil, label: demo ? "시험" : "OTP", generatedAt: now, demo: demo, showWhenLocked: false, message: message))
    }
    private func makeTimeline() -> Timeline<OTPEntry> {
        let now = Date()
        do {
            let vault = try KeychainVault.load()
            guard vault.demoMode || vault.widgetsEnabled else {
                return Timeline(entries: [unavailable("앱에서 허용")], policy: .after(now.addingTimeInterval(900)))
            }
            guard let account = vault.selected else {
                return Timeline(entries: [unavailable("계정 선택")], policy: .after(now.addingTimeInterval(900)))
            }
            let values = try TimelineSchedule.entries(secret: account.secret, now: now, count: vault.entryCount, period: account.period, digits: account.digits, algorithm: account.algorithm)
            let entries = values.map { value in
                OTPEntry(date: value.date, display: OTPDisplayEntry(date: value.date, validUntil: value.validUntil, code: value.code, label: account.label, generatedAt: value.generatedAt, demo: vault.demoMode, showWhenLocked: vault.showWhenLocked, message: value.code == nil ? "기간 만료" : nil))
            }
            let end = values.last!.date
            return Timeline(entries: entries, policy: .after(end.addingTimeInterval(-min(300, end.timeIntervalSince(now) / 2))))
        } catch {
            return Timeline(entries: [unavailable("잠금 해제")], policy: .after(now.addingTimeInterval(900)))
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
        StaticConfiguration(kind: "LockscreenOTP", provider: OTPProvider()) { entry in OTPWidgetView(entry: entry) }
            .configurationDisplayName("잠금 OTP")
            .description("선택한 계정의 인증번호를 표시합니다. 자동 갱신은 실험 기능입니다.")
            .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}
