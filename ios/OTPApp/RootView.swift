import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: VaultStore
    @State private var adding = false
    @State private var confirmWidget = false
    @State private var confirmLocked = false
    @State private var deleteTarget: OTPAccount?
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { accounts }.tabItem { Label("인증번호", systemImage: "key.fill") }.tag(0)
            NavigationStack { settings }.tabItem { Label("위젯", systemImage: "lock.rectangle") }.tag(1)
            NavigationStack { DiagnosticView() }.tabItem { Label("검증", systemImage: "waveform.path.ecg") }.tag(2)
        }
        .sheet(isPresented: $adding) { AddAccountView() }
        .alert("저장하지 못했어요", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("확인", role: .cancel) { store.error = nil }
        } message: { Text(store.error ?? "") }
        .confirmationDialog("계정을 삭제할까요?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                guard let target = deleteTarget else { return }
                store.change { value in
                    value.accounts.removeAll { $0.id == target.id }
                    if value.selectedID == target.id { value.selectedID = value.accounts.first?.id }
                }
                deleteTarget = nil
            }
            Button("취소", role: .cancel) { deleteTarget = nil }
        } message: { Text("키는 복구할 수 없습니다. 시스템 위젯에 이미 전달한 코드는 갱신 전까지 남을 수 있습니다.") }
    }

    private var accounts: some View {
        List {
            Section {
                Label("자동 갱신 검증 중", systemImage: "flask")
                    .foregroundStyle(.orange)
                Text("인증번호는 기기에서만 계산합니다. 잠금 화면의 정확한 전환은 아직 보장하지 않습니다.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if store.vault.demoMode {
                Section("공개 시험키") { AccountCodeRow(account: .demo, selected: true) }
            }
            Section("내 계정") {
                if store.vault.accounts.isEmpty {
                    Text("등록된 계정이 없습니다.").foregroundStyle(.secondary)
                }
                ForEach(store.vault.accounts) { account in
                    Button {
                        store.change { $0.selectedID = account.id; $0.demoMode = false }
                    } label: {
                        AccountCodeRow(account: account, selected: !store.vault.demoMode && store.vault.selectedID == account.id)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("삭제", role: .destructive) { deleteTarget = account }
                    }
                }
            }
            Section {
                Button { adding = true } label: { Label("계정 추가", systemImage: "plus") }
                    .accessibilityIdentifier("add-account")
                    .disabled(!store.ready)
            } footer: {
                Text("다른 인증 앱의 코드를 읽어오지 않습니다. 서비스에서 제공하는 비밀키나 등록 주소가 필요합니다. 기존 인증 수단은 검증 전까지 유지하세요.")
            }
        }
        .navigationTitle("잠금 OTP")
    }

    private var settings: some View {
        Form {
            Section("표시할 계정") {
                Toggle("시험키 사용", isOn: Binding(get: { store.vault.demoMode }, set: { value in store.change { $0.demoMode = value } }))
                if !store.vault.demoMode { Text(store.vault.selected?.label ?? "인증번호 탭에서 계정을 선택하세요.") }
            }
            Section {
                Toggle("실제 계정 위젯 허용", isOn: Binding(get: { store.vault.widgetsEnabled }, set: { value in
                    if value { confirmWidget = true }
                    else { store.change { $0.widgetsEnabled = false; $0.showWhenLocked = false } }
                }))
                Toggle("잠긴 상태에서도 번호 표시", isOn: Binding(get: { store.vault.showWhenLocked }, set: { value in
                    if value { confirmLocked = true } else { store.change { $0.showWhenLocked = false } }
                })).disabled(!store.vault.widgetsEnabled)
            } header: { Text("노출 범위") } footer: {
                Text("위젯을 허용하면 저장된 계정 키는 재부팅 후 첫 잠금 해제부터 접근 가능하도록 보관됩니다. 기본값은 잠금 중 번호 숨김입니다. 이미 만들어진 위젯 화면은 설정 변경 직후에도 남을 수 있습니다.")
            }
            Section("사전 계산 범위") {
                Picker("준비할 코드", selection: Binding(get: { store.vault.entryCount }, set: { count in store.change { $0.entryCount = count } })) {
                    Text("20개 · 기본 약 10분").tag(20)
                    Text("120개 · 기본 약 1시간").tag(120)
                    Text("720개 · 기본 약 6시간").tag(720)
                }
                Text("30초 주기 기준입니다. 길게 준비해도 정확한 표시 전환이나 갱신이 보장되지는 않습니다.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button("위젯 새로고침 요청") { store.requestReload() }
                if let date = store.requestedAt {
                    LabeledContent("요청 시각", value: date.formatted(date: .omitted, time: .standard))
                }
                Text("요청은 즉시 갱신 완료를 뜻하지 않습니다.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("추가 방법") {
                Text("잠금 화면 길게 누르기 → 사용자화 → 위젯 영역 → 잠금 OTP")
                Text("원형 한 칸과 시간 위 한 줄을 지원합니다. 위젯을 누르면 앱을 엽니다.")
            }
        }
        .disabled(!store.ready)
        .navigationTitle("잠금 화면 위젯")
        .alert("위젯 접근을 허용할까요?", isPresented: $confirmWidget) {
            Button("허용") { store.change { $0.widgetsEnabled = true } }
            Button("취소", role: .cancel) { }
        } message: { Text("저장된 계정 키 전체가 첫 잠금 해제 후 백그라운드에서 접근 가능한 키체인 보호 등급으로 바뀝니다. 키는 기기를 떠나지 않습니다. 자동 갱신은 실험 기능입니다.") }
        .alert("잠긴 상태에서 노출할까요?", isPresented: $confirmLocked) {
            Button("번호 표시") { store.change { $0.showWhenLocked = true } }
            Button("취소", role: .cancel) { }
        } message: { Text("아이폰을 가진 사람이 인증번호를 볼 수 있습니다. 상시 표시 화면에서도 노출될 수 있습니다.") }
    }
}

struct AccountCodeRow: View {
    let account: OTPAccount
    let selected: Bool
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date.timeIntervalSince1970
            let code = (try? TOTPEngine.code(secret: account.secret, timestamp: now, digits: account.digits, period: account.period, algorithm: account.algorithm)) ?? "—"
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(account.label).font(.headline).lineLimit(1)
                    Spacer()
                    if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(code).font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit()).minimumScaleFactor(0.5)
                    Spacer()
                    Text("\(account.period - Int(now) % account.period)초").foregroundStyle(.secondary)
                }
                ProgressView(value: Double(account.period) - now.truncatingRemainder(dividingBy: Double(account.period)), total: Double(account.period))
            }.padding(.vertical, 8)
        }
        .privacySensitive()
    }
}
