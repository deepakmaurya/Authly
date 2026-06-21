import Foundation

enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let charMap: [Character: UInt8] = {
        var m: [Character: UInt8] = [:]
        for (i, c) in alphabet.enumerated() { m[c] = UInt8(i) }
        return m
    }()

    static func decode(_ input: String) -> Data? {
        let cleaned = input.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "=", with: "")
            .uppercased()
        if cleaned.isEmpty { return nil }

        var bits: UInt64 = 0
        var bitCount: Int = 0
        var out = Data()
        out.reserveCapacity((cleaned.count * 5) / 8)

        for ch in cleaned {
            guard let v = charMap[ch] else { return nil }
            bits = (bits << 5) | UInt64(v)
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                let byte = UInt8((bits >> bitCount) & 0xFF)
                out.append(byte)
            }
        }
        return out
    }

    static func encode(_ data: Data) -> String {
        if data.isEmpty { return "" }
        var bits: UInt64 = 0
        var bitCount: Int = 0
        var out = ""
        out.reserveCapacity((data.count * 8 + 4) / 5)
        for byte in data {
            bits = (bits << 8) | UInt64(byte)
            bitCount += 8
            while bitCount >= 5 {
                bitCount -= 5
                let idx = Int((bits >> bitCount) & 0x1F)
                out.append(alphabet[idx])
            }
        }
        if bitCount > 0 {
            let idx = Int((bits << (5 - bitCount)) & 0x1F)
            out.append(alphabet[idx])
        }
        return out
    }
}
