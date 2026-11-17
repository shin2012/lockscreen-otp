import SwiftUI

struct DiagnosticView: View {
    @EnvironmentObject private var store: VaultStore
    var body: some View {
        List {
            Section("시험키 기준 · 실제 계정과 무관") {
                AccountCodeRow(account: .demo, selected: false)
                Text("위젯의 시험 번호와 비교하세요. 이 화면은 앱 전경 타이머이며 위젯 자동 갱신의 성공 근거는 아닙니다.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("위젯 모양 미리보기 · 시험키") {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let now = context.date
                    let until = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 30) + 1) * 30)
                    let code = try? TOTPEngine.code(secret: OTPAccount.demo.secret, timestamp: now.timeIntervalSince1970)
                    let entry = OTPDisplayEntry(date: now, validUntil: until, code: code, label: "시험", generatedAt: now, demo: true, showWhenLocked: false, message: nil)
                    HStack(spacing: 24) {
                        CircularOTPView(entry: entry).frame(width: 64, height: 64).background(.quaternary, in: Circle())
                        InlineOTPView(entry: entry)
                    }.padding(.vertical, 10)
                }
            }
            Section("확인할 조건") {
                Text("앱을 닫고 잠금 화면의 번호가 30초 경계마다 바뀌는지 확인")
                Text("Face ID 전·후를 구분하고 상시 표시 화면·저전력·비행기 모드에서 확인")
                Text("밤새 방치 후 첫 화면과 사전 계산 기간이 지난 뒤 확인")
                Text("실제 계정을 등록하기 전에 시험키로 먼저 검증하세요.").foregroundStyle(.orange)
            }
            Section("기기 정보") {
                LabeledContent("시스템", value: UIDevice.current.systemVersion)
                LabeledContent("앱", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                LabeledContent("빌드", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")
                Text("키·코드·계정명은 진단 로그로 전송하지 않습니다.").font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("자동 갱신 검증")
    }
}
