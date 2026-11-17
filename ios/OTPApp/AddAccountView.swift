import SwiftUI
import OSLog

struct AddAccountView: View {
    @EnvironmentObject private var store: VaultStore
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var secret = ""
    @State private var uri = ""
    @State private var digits = 6
    @State private var period = 30
    @State private var algorithm = "sha1"
    @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("직접 입력") {
                    TextField("계정 이름", text: $label).accessibilityIdentifier("account-label")
                    SecureField("비밀키 · Base32", text: $secret)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .accessibilityIdentifier("account-secret")
                    Picker("자리 수", selection: $digits) { Text("6자리").tag(6); Text("8자리").tag(8) }
                    Picker("주기", selection: $period) { Text("30초").tag(30); Text("60초").tag(60) }
                    Picker("알고리즘", selection: $algorithm) {
                        Text("SHA-1").tag("sha1"); Text("SHA-256").tag("sha256"); Text("SHA-512").tag("sha512")
                    }
                }
                Section {
                    SecureField("otpauth:// 등록 주소", text: $uri)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                } header: { Text("또는 등록 주소 붙여넣기") } footer: {
                    Text("주소를 입력하면 직접 입력한 설정보다 우선합니다. 문자 코드·푸시 승인·전용 은행 OTP는 지원하지 않습니다.")
                }
                if let message { Text(message).foregroundStyle(.red).accessibilityIdentifier("input-error") }
                Section {
                    Text("키는 이 기기의 키체인에만 저장합니다. 동기화·내보내기·복구 기능이 없으므로 기존 인증 수단을 유지하세요.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("계정 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { clear(); dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("저장") { save() }.accessibilityIdentifier("save-account") }
            }
        }.onDisappear { clear() }
    }
    private func clear() { secret = ""; uri = "" }
    private func save() {
        #if DEBUG && targetEnvironment(simulator)
        Logger(subsystem: "kr.b-612.lockscreenotp", category: "input").notice("save entered labelPresent=\(!label.isEmpty, privacy: .public) keyPresent=\(!secret.isEmpty, privacy: .public)")
        #endif
        do {
            let account: OTPAccount
            if !uri.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                account = try OTPURIParser.parse(uri)
            } else {
                let name = label.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, name.count <= 120 else { message = "계정 이름을 1~120자로 입력하세요."; return }
                account = OTPAccount(label: name, secret: try Base32.decode(secret), digits: digits, period: period, algorithm: OTPAlgorithm(rawValue: algorithm) ?? .sha1)
            }
            guard store.vault.accounts.count < 100 else { message = "계정은 최대 100개까지 저장할 수 있습니다."; return }
            let previous = store.vault.accounts.count
            store.change { $0.accounts.append(account); $0.selectedID = account.id; $0.demoMode = false }
            if store.vault.accounts.count > previous { clear(); dismiss() }
            else { message = "키체인 저장에 실패했습니다. 상위 화면의 오류를 확인하세요." }
        } catch { message = "비밀키 또는 등록 주소 형식을 확인하세요. 표준 TOTP만 지원합니다." }
    }
}
