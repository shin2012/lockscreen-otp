import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: VaultStore
    @State private var adding = false
    @State private var editing: OTPAccount?
    @State private var confirmWidget = false
    @State private var confirmLocked = false
    @State private var deleteTarget: OTPAccount?
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { accounts }.tabItem { Label("인증번호", systemImage: "key.fill") }.tag(0)
            NavigationStack { settings }.tabItem { Label("위젯", systemImage: "lock.rectangle") }.tag(1)
        }
        .sheet(isPresented: $adding) { AddAccountView() }
        .sheet(item: $editing) { account in EditAccountView(account: account) }
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
            }.accessibilityIdentifier("confirm-delete")
            Button("취소", role: .cancel) { deleteTarget = nil }
        } message: { Text("키는 복구할 수 없습니다. 시스템 위젯에 이미 전달한 코드는 갱신 전까지 남을 수 있습니다.") }
    }

    private var accounts: some View {
        List {
            Section {
                if store.vault.accounts.isEmpty {
                    Text("등록된 계정이 없습니다.").foregroundStyle(.secondary)
                }
                ForEach(store.vault.accounts) { account in
                    AccountCodeRow(account: account, isDefault: store.vault.selected?.id == account.id)
                        .contentShape(Rectangle())
                        .swipeActions {
                            Button("삭제", role: .destructive) { deleteTarget = account }
                            Button("편집") { editing = account }.tint(.blue)
                        }
                        .contextMenu {
                            Button { editing = account } label: { Label("이름 편집", systemImage: "pencil") }
                            Button { store.change { $0.selectedID = account.id } } label: { Label("기본 계정으로", systemImage: "star") }
                            Button(role: .destructive) { deleteTarget = account } label: { Label("삭제", systemImage: "trash") }
                        }
                }
                .onMove { from, to in store.change { $0.accounts.move(fromOffsets: from, toOffset: to) } }
            } footer: {
                if !store.vault.accounts.isEmpty {
                    Text("왼쪽으로 밀어 편집·삭제, 길게 눌러 기본 계정 지정. 별표는 위젯에서 계정을 고르지 않았을 때 보여줄 기본 계정입니다.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("잠금 OTP")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("계정 추가")
                    .accessibilityIdentifier("add-account")
                    .disabled(!store.ready)
            }
            if store.vault.accounts.count > 1 {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
            }
        }
    }

    private var settings: some View {
        Form {
            Section {
                Toggle("위젯에서 계정 사용", isOn: Binding(get: { store.vault.widgetsEnabled }, set: { value in
                    if value { confirmWidget = true }
                    else { store.change { $0.widgetsEnabled = false; $0.showWhenLocked = false } }
                }))
                Toggle("잠긴 상태에서도 번호 표시", isOn: Binding(get: { store.vault.showWhenLocked }, set: { value in
                    if value { confirmLocked = true } else { store.change { $0.showWhenLocked = false } }
                })).disabled(!store.vault.widgetsEnabled)
            } header: { Text("노출 범위") } footer: {
                Text("위젯을 허용하면 계정 키는 재부팅 후 첫 잠금 해제부터 위젯이 읽을 수 있도록 보관됩니다. 키는 기기를 떠나지 않습니다.")
            }
            Section("기본 계정") {
                Text(store.vault.selected?.label ?? "계정을 먼저 추가하세요.")
                    .foregroundStyle(store.vault.selected == nil ? .secondary : .primary)
            }
            Section {
                Picker("미리 준비할 번호", selection: Binding(get: { store.vault.entryCount }, set: { count in store.change { $0.entryCount = count } })) {
                    Text("약 10분").tag(20)
                    Text("약 1시간").tag(120)
                    Text("약 6시간").tag(720)
                }
                Button("위젯 새로고침") { store.requestReload() }
            } footer: { Text("30초 주기 기준입니다. 위젯은 이 범위의 번호를 미리 받아 두고 시간에 맞춰 바꿉니다.") }
            Section("위젯 추가와 설정") {
                Text("잠금 화면 길게 누르기 → 사용자화 → 위젯 영역 → 잠금 OTP")
                Text("추가한 위젯을 누르면 계정, 이름 표시, 남은 시간 링 두께, 상시 표시 화면 동작을 위젯마다 고를 수 있습니다.")
                Text("상시 표시 화면(AOD)에서는 iOS가 위젯을 거의 다시 그리지 않아 번호가 멈춥니다. 기본값은 AOD에서 번호를 가리는 것입니다.")
                    .foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("버전", value: "\(Self.info("CFBundleShortVersionString")) (\(Self.info("CFBundleVersion")))")
            }
        }
        .disabled(!store.ready)
        .navigationTitle("잠금 화면 위젯")
        .alert("위젯 접근을 허용할까요?", isPresented: $confirmWidget) {
            Button("허용") { store.change { $0.widgetsEnabled = true } }
            Button("취소", role: .cancel) { }
        } message: { Text("저장된 계정 키 전체가 첫 잠금 해제 후 백그라운드에서 접근 가능한 키체인 보호 등급으로 바뀝니다. 키는 기기를 떠나지 않습니다.") }
        .alert("잠긴 상태에서 노출할까요?", isPresented: $confirmLocked) {
            Button("번호 표시") { store.change { $0.showWhenLocked = true } }
            Button("취소", role: .cancel) { }
        } message: { Text("아이폰을 가진 사람이 인증번호를 볼 수 있습니다.") }
    }
}

extension RootView {
    static func info(_ key: String) -> String { Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "-" }
}

struct AccountCodeRow: View {
    let account: OTPAccount
    let isDefault: Bool
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date.timeIntervalSince1970
            let code = (try? TOTPEngine.code(secret: account.secret, timestamp: now, digits: account.digits, period: account.period, algorithm: account.algorithm)) ?? "—"
            let remaining = Double(account.period) - now.truncatingRemainder(dividingBy: Double(account.period))
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(account.label).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        if isDefault { Image(systemName: "star.fill").font(.caption2).foregroundStyle(.tint).accessibilityLabel("기본 계정") }
                    }
                    Text(spaced(code))
                        .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(remaining <= 5 ? Color.orange : Color.primary)
                }
                Spacer(minLength: 8)
                CountdownRing(remaining: remaining, total: Double(account.period))
            }
            .padding(.vertical, 2)
        }
        .privacySensitive()
    }
    private func spaced(_ code: String) -> String {
        guard code.count >= 6 else { return code }
        let half = code.count / 2
        return "\(code.prefix(half)) \(code.suffix(code.count - half))"
    }
}

struct CountdownRing: View {
    let remaining: Double
    let total: Double
    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 3)
            Circle().trim(from: 0, to: max(0, min(1, remaining / total)))
                .stroke(remaining <= 5 ? Color.orange : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(remaining.rounded(.up)))").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
        .frame(width: 28, height: 28)
        .accessibilityLabel("\(Int(remaining.rounded(.up)))초 남음")
    }
}
