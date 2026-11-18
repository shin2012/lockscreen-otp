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
        // Account names are listed only after the app-level widget opt-in, matching key access.
        guard let vault = try? KeychainVault.load(), vault.widgetsEnabled else { return [] }
        return vault.accounts.map { OTPAccountEntity(id: $0.id.uuidString, name: $0.label) }
    }
}

struct OTPWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "잠금 OTP 설정"
    static var description = IntentDescription("표시할 계정과 표시 방식을 고릅니다.")

    @Parameter(title: "계정", description: "비워 두면 앱의 기본 계정(별표)을 따릅니다.")
    var account: OTPAccountEntity?

    @Parameter(title: "이름 표시", default: true)
    var showName: Bool

    @Parameter(title: "남은 시간 표시", default: .bar)
    var ring: OTPRingStyle

    @Parameter(title: "상시 표시 화면에서 번호 가리기", description: "AOD에서는 위젯이 갱신되지 않아 지난 번호가 남습니다.", default: true)
    var hideInAOD: Bool

    init() {}
}

extension OTPRingStyle: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "남은 시간 표시"
    static var caseDisplayRepresentations: [OTPRingStyle: DisplayRepresentation] = [
        .bar: "번호 아래 막대", .ring: "테두리 링", .seconds: "남은 초", .none: "표시 안 함"
    ]
}
