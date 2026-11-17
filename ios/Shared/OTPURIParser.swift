import Foundation
public enum OTPURIParser {
    public enum ParseError: Error { case invalid }
    public static func parse(_ input: String) throws -> OTPAccount {
        guard input.utf8.count <= 8192,
              let url = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "otpauth", url.host?.lowercased() == "totp",
              url.user == nil, url.password == nil, url.port == nil, url.fragment == nil else { throw ParseError.invalid }
        var fields: [String: String] = [:]
        for item in url.queryItems ?? [] {
            let key = item.name.lowercased()
            guard fields[key] == nil, let value = item.value else { throw ParseError.invalid }
            fields[key] = value
        }
        let label = String(url.path.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty, label.count <= 120, let encoded = fields["secret"] else { throw ParseError.invalid }
        let algorithmString = (fields["algorithm"] ?? "sha1").lowercased()
        guard let algorithm = OTPAlgorithm(rawValue: algorithmString),
              let digits = Int(fields["digits"] ?? "6"), [6, 8].contains(digits),
              let period = Int(fields["period"] ?? "30"), (1...3600).contains(period) else { throw ParseError.invalid }
        let secret = try Base32.decode(encoded)
        let issuer = fields["issuer"] ?? ""
        let name = !issuer.isEmpty && !label.contains(":") ? "\(issuer):\(label)" : label
        guard name.count <= 120 else { throw ParseError.invalid }
        return OTPAccount(label: name, secret: secret, digits: digits, period: period, algorithm: algorithm)
    }
}
