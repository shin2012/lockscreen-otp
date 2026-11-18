import SwiftUI

struct MacAddAccountView: View {
    @EnvironmentObject private var store: VaultStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode = OTPInputMode.manual
    @State private var label = ""
    @State private var secret = ""
    @State private var uri = ""
    @State private var digits = 6
    @State private var period = 30
    @State private var algorithm = "sha1"
    @State private var message: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("계정 추가").font(.title3.bold())
            Picker("등록 방법", selection: $mode) {
                Text("비밀키").tag(OTPInputMode.manual)
                Text("등록 주소").tag(OTPInputMode.uri)
            }.pickerStyle(.segmented).labelsHidden()
            Form {
                if mode == .manual {
                    TextField("계정 이름", text: $label)
                    SecureField("비밀키 · Base32", text: $secret)
                    Picker("자리 수", selection: $digits) { Text("6자리").tag(6); Text("8자리").tag(8) }
                    Picker("주기", selection: $period) { Text("30초").tag(30); Text("60초").tag(60) }
                    Picker("알고리즘", selection: $algorithm) {
                        Text("SHA-1").tag("sha1"); Text("SHA-256").tag("sha256"); Text("SHA-512").tag("sha512")
                    }
                } else {
                    SecureField("otpauth:// 등록 주소", text: $uri)
                }
            }
            if let message { Text(message).foregroundStyle(.red).font(.callout) }
            Text("키는 이 Mac의 키체인에만 저장합니다. 동기화·내보내기 기능이 없으므로 기존 인증 수단을 유지하세요.")
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("취소") { clear(); dismiss() }.keyboardShortcut(.cancelAction)
                Button("저장") { save() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onChange(of: mode) { _, _ in clear(); message = nil }
        .onDisappear { clear() }
    }
    private func clear() { secret = ""; uri = "" }
    private func save() {
        do {
            let account = try OTPAccountInput.build(mode: mode, label: label, secret: secret, uri: uri, digits: digits, period: period, algorithm: OTPAlgorithm(rawValue: algorithm) ?? .sha1)
            guard store.vault.accounts.count < 100 else { message = "계정은 최대 100개까지 저장할 수 있습니다."; return }
            let previous = store.vault.accounts.count
            store.change { $0.accounts.append(account); if $0.selectedID == nil { $0.selectedID = account.id } }
            if store.vault.accounts.count > previous { clear(); dismiss() }
            else { message = "키체인 저장에 실패했습니다." }
        } catch OTPAccountInput.InputError.invalidLabel {
            message = "계정 이름을 1~120자로 입력하세요."
        } catch {
            message = mode == .manual ? "비밀키는 영문과 2~7로 된 Base32 형식인지 확인하세요." : "등록 주소 형식을 확인하세요. 표준 TOTP만 지원합니다."
        }
    }
}

struct MacEditAccountView: View {
    @EnvironmentObject private var store: VaultStore
    @Environment(\.dismiss) private var dismiss
    let account: OTPAccount
    @State private var label = ""
    @State private var message: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("계정 편집").font(.title3.bold())
            Form {
                TextField("계정 이름", text: $label)
                LabeledContent("자리 수", value: "\(account.digits)자리")
                LabeledContent("주기", value: "\(account.period)초")
                LabeledContent("알고리즘", value: account.algorithm.rawValue.uppercased())
            }
            if let message { Text(message).foregroundStyle(.red).font(.callout) }
            Text("비밀키와 생성 방식은 바꿀 수 없습니다.").font(.footnote).foregroundStyle(.secondary)
            HStack {
                Button("기본 계정으로 지정") { store.change { $0.selectedID = account.id }; dismiss() }
                    .disabled(store.vault.selected?.id == account.id)
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("저장") { save() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear { label = account.label }
    }
    private func save() {
        do {
            let next = try OTPAccountEditor.rename(store.vault.accounts, id: account.id, to: label)
            store.change { $0.accounts = next }
            dismiss()
        } catch OTPAccountEditor.EditError.invalidLabel {
            message = "계정 이름을 1~120자로 입력하세요."
        } catch {
            message = "계정을 찾을 수 없습니다."
        }
    }
}

struct MacSettingsView: View {
    @EnvironmentObject private var store: VaultStore
    @State private var confirmWidget = false
    var body: some View {
        Form {
            Section {
                Toggle("위젯에서 계정 사용", isOn: Binding(get: { store.vault.widgetsEnabled }, set: { value in
                    if value { confirmWidget = true } else { store.change { $0.widgetsEnabled = false } }
                }))
            } footer: {
                Text("허용하면 위젯 확장이 이 Mac의 키체인에서 계정 키를 읽어 번호를 만듭니다. 키는 Mac을 떠나지 않습니다.")
            }
            Section {
                LabeledContent("기본 계정", value: store.vault.selected?.label ?? "없음")
                Picker("미리 준비할 번호", selection: Binding(get: { store.vault.entryCount }, set: { count in store.change { $0.entryCount = count } })) {
                    Text("약 10분").tag(20)
                    Text("약 1시간").tag(120)
                    Text("약 6시간").tag(720)
                }
            }
            Section("위젯 추가") {
                Text("데스크톱 빈 곳을 오른쪽 클릭 → 위젯 편집 → 잠금 OTP. 위젯을 오른쪽 클릭 → 위젯 편집에서 계정과 표시 방식을 고릅니다.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            LabeledContent("버전", value: "\(Self.info("CFBundleShortVersionString")) (\(Self.info("CFBundleVersion")))")
        }
        .formStyle(.grouped)
        .disabled(!store.ready)
        .alert("위젯 접근을 허용할까요?", isPresented: $confirmWidget) {
            Button("허용") { store.change { $0.widgetsEnabled = true } }
            Button("취소", role: .cancel) { }
        } message: { Text("저장된 계정 키를 위젯이 백그라운드에서 읽을 수 있게 됩니다.") }
    }
    static func info(_ key: String) -> String { Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "-" }
}
