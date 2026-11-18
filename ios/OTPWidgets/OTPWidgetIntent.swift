import AppIntents
import WidgetKit

/// A stored account offered in the widget's edit sheet. Only the id and name leave the vault.
struct OTPAccountEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "OTP 계정"
    static var defaultQuery = OTPAccountQuery()
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct OTPAccountQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [OTPAccountEntity] {
        allEntities().filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [OTPAccountEntity] { allEntities() }

    private func allEntities() -> [OTPAccountEntity] {
        let demo = OTPAccountEntity(id: OTPAccount.demo.id.uuidString, name: "시험 (공개 시험키)")
        // Account names are listed only after the app-level widget opt-in, matching key access.
        guard let vault = try? KeychainVault.load(), vault.widgetsEnabled else { return [demo] }
        return vault.accounts.map { OTPAccountEntity(id: $0.id.uuidString, name: $0.label) } + [demo]
    }
}

struct OTPWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "잠금 OTP 설정"
    static var description = IntentDescription("표시할 계정과 이름 표시 여부를 고릅니다.")

    @Parameter(title: "계정", description: "비워 두면 앱에서 선택한 계정을 따릅니다.")
    var account: OTPAccountEntity?

    @Parameter(title: "이름 표시", default: true)
    var showName: Bool

    init() {}
}
