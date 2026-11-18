import Foundation

/// Edits account metadata. The key, digits, period and algorithm are never touched,
/// so a rename can't change the codes an account produces.
public enum OTPAccountEditor {
    public enum EditError: Error { case invalidLabel, notFound }
    public static func rename(_ accounts: [OTPAccount], id: UUID, to name: String) throws -> [OTPAccount] {
        let label = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty, label.count <= 120 else { throw EditError.invalidLabel }
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { throw EditError.notFound }
        var result = accounts
        result[index].label = label
        return result
    }
}
