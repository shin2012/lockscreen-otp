import SwiftUI
import AppKit

struct MacRootView: View {
    @EnvironmentObject private var store: VaultStore
    @State private var adding = false
    @State private var editing: OTPAccount?
    @State private var deleteTarget: OTPAccount?
    @State private var copiedID: UUID?
    var body: some View {
        Group {
            if store.vault.accounts.isEmpty {
                ContentUnavailableView {
                    Label("등록된 계정이 없습니다", systemImage: "key")
                } description: {
                    Text("계정을 추가한 뒤 설정에서 위젯 사용을 허용하면 데스크톱·알림 센터 위젯에 인증번호가 표시됩니다.")
                } actions: {
                    Button("계정 추가") { adding = true }.disabled(!store.ready)
                }
            } else {
                List {
                    ForEach(store.vault.accounts) { account in
                        MacCodeRow(account: account, isDefault: store.vault.selected?.id == account.id, copied: copiedID == account.id) { code in
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(code, forType: .string)
                            copiedID = account.id
                            Task { try? await Task.sleep(for: .seconds(1.5)); if copiedID == account.id { copiedID = nil } }
                        }
                        .contextMenu {
                            Button("이름 편집") { editing = account }
                            Button("기본 계정으로") { store.change { $0.selectedID = account.id } }
                            Divider()
                            Button("삭제", role: .destructive) { deleteTarget = account }
                        }
                    }
                    .onMove { from, to in store.change { $0.accounts.move(fromOffsets: from, toOffset: to) } }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .safeAreaInset(edge: .bottom) {
                    Text("번호를 클릭하면 복사됩니다. 오른쪽 클릭으로 편집·기본 계정·삭제.")
                        .font(.caption).foregroundStyle(.secondary).padding(8)
                }
            }
        }
        .navigationTitle("잠금 OTP")
        .toolbar {
            ToolbarItem {
                Button { adding = true } label: { Label("계정 추가", systemImage: "plus") }.disabled(!store.ready)
            }
            ToolbarItem {
                SettingsLink { Label("위젯 설정", systemImage: "gearshape") }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .otpAddAccount)) { _ in adding = true }
        .sheet(isPresented: $adding) { MacAddAccountView().environmentObject(store) }
        .sheet(item: $editing) { account in MacEditAccountView(account: account).environmentObject(store) }
        .alert("저장하지 못했어요", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("확인", role: .cancel) { store.error = nil }
        } message: { Text(store.error ?? "") }
        .confirmationDialog("계정을 삭제할까요?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("삭제", role: .destructive) {
                guard let target = deleteTarget else { return }
                store.change { value in
                    value.accounts.removeAll { $0.id == target.id }
                    if value.selectedID == target.id { value.selectedID = value.accounts.first?.id }
                }
                deleteTarget = nil
            }
            Button("취소", role: .cancel) { deleteTarget = nil }
        } message: { Text("키는 복구할 수 없습니다.") }
    }
}

struct MacCodeRow: View {
    let account: OTPAccount
    let isDefault: Bool
    let copied: Bool
    let copy: (String) -> Void
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date.timeIntervalSince1970
            let code = (try? TOTPEngine.code(secret: account.secret, timestamp: now, digits: account.digits, period: account.period, algorithm: account.algorithm)) ?? "—"
            let remaining = Double(account.period) - now.truncatingRemainder(dividingBy: Double(account.period))
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(account.label).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        if isDefault { Image(systemName: "star.fill").font(.caption2).foregroundStyle(.tint) }
                    }
                    Text(MacCodeRow.spaced(code))
                        .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(remaining <= 5 ? Color.orange : Color.primary)
                }
                Spacer(minLength: 8)
                if copied {
                    Label("복사됨", systemImage: "checkmark").font(.caption).foregroundStyle(.green)
                }
                MacCountdownRing(remaining: remaining, total: Double(account.period))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture { if code != "—" { copy(code) } }
            .help("클릭하여 복사")
        }
    }
    static func spaced(_ code: String) -> String {
        guard code.count >= 6 else { return code }
        let half = code.count / 2
        return "\(code.prefix(half)) \(code.suffix(code.count - half))"
    }
}

struct MacCountdownRing: View {
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
    }
}
