import SwiftUI

struct EditAccountView: View {
    @EnvironmentObject private var store: VaultStore
    @Environment(\.dismiss) private var dismiss
    let account: OTPAccount
    @State private var label = ""
    @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("계정 이름", text: $label).accessibilityIdentifier("edit-label")
                }
                if let message { Text(message).foregroundStyle(.red) }
                Section {
                    LabeledContent("자리 수", value: "\(account.digits)자리")
                    LabeledContent("주기", value: "\(account.period)초")
                    LabeledContent("알고리즘", value: account.algorithm.rawValue.uppercased())
                    Button("기본 계정으로 지정") { store.change { $0.selectedID = account.id }; dismiss() }
                        .disabled(store.vault.selected?.id == account.id)
                } footer: {
                    Text("비밀키와 생성 방식은 바꿀 수 없습니다. 바꾸려면 계정을 새로 추가하세요.")
                }
            }
            .navigationTitle("계정 편집")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { label = account.label }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("저장") { save() }.accessibilityIdentifier("save-edit") }
            }
        }
    }
    private func save() {
        do {
            let next = try OTPAccountEditor.rename(store.vault.accounts, id: account.id, to: label)
            store.change { $0.accounts = next }
            if store.vault.accounts.first(where: { $0.id == account.id })?.label == next.first(where: { $0.id == account.id })?.label { dismiss() }
        } catch OTPAccountEditor.EditError.invalidLabel {
            message = "계정 이름을 1~120자로 입력하세요."
        } catch {
            message = "계정을 찾을 수 없습니다. 이미 삭제되었을 수 있습니다."
        }
    }
}
