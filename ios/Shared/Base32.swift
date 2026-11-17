import Foundation
public enum Base32 {
    public enum DecodeError: Error { case invalid }
    public static func decode(_ input: String) throws -> Data {
        let clean = input.filter { !$0.isWhitespace }.uppercased()
        guard !clean.isEmpty, clean.utf8.count <= 4096 else { throw DecodeError.invalid }
        let parts = clean.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let body = String(parts[0])
        let remainder = body.utf8.count % 8
        guard [0, 2, 4, 5, 7].contains(remainder) else { throw DecodeError.invalid }
        if parts.count == 2 {
            guard parts[1].allSatisfy({ $0 == "=" }), clean.count % 8 == 0,
                  remainder != 0, clean.count - body.count == 8 - remainder else { throw DecodeError.invalid }
        }
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8)
        var buffer: UInt32 = 0
        var bits = 0
        var result = Data()
        for character in body.utf8 {
            guard let value = alphabet.firstIndex(of: character) else { throw DecodeError.invalid }
            buffer = (buffer << 5) | UInt32(value)
            bits += 5
            if bits >= 8 {
                bits -= 8
                result.append(UInt8((buffer >> bits) & 255))
                buffer &= (1 << bits) - 1
            }
        }
        guard buffer == 0, !result.isEmpty else { throw DecodeError.invalid }
        return result
    }
}
