import Foundation
import CryptoKit

enum OTPAlgorithm: String, Codable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

enum TOTPGenerator {
    static func code(secret: Data, date: Date = Date(), digits: Int = 6, period: Int = 30, algorithm: OTPAlgorithm = .sha1) -> String {
        let counter = UInt64(floor(date.timeIntervalSince1970 / Double(period)))
        return hotp(secret: secret, counter: counter, digits: digits, algorithm: algorithm)
    }

    static func progress(date: Date = Date(), period: Int = 30) -> Double {
        let t = date.timeIntervalSince1970
        let elapsed = t.truncatingRemainder(dividingBy: Double(period))
        return elapsed / Double(period)
    }

    static func secondsRemaining(date: Date = Date(), period: Int = 30) -> Int {
        let t = Int(date.timeIntervalSince1970)
        return period - (t % period)
    }

    private static func hotp(secret: Data, counter: UInt64, digits: Int, algorithm: OTPAlgorithm) -> String {
        var bigCounter = counter.bigEndian
        let counterData = Data(bytes: &bigCounter, count: MemoryLayout<UInt64>.size)
        let key = SymmetricKey(data: secret)

        let macData: Data
        switch algorithm {
        case .sha1:
            macData = Data(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key))
        case .sha256:
            macData = Data(HMAC<SHA256>.authenticationCode(for: counterData, using: key))
        case .sha512:
            macData = Data(HMAC<SHA512>.authenticationCode(for: counterData, using: key))
        }

        let offset = Int(macData[macData.count - 1] & 0x0F)
        let truncated = (UInt32(macData[offset]) & 0x7F) << 24
            | (UInt32(macData[offset + 1]) & 0xFF) << 16
            | (UInt32(macData[offset + 2]) & 0xFF) << 8
            | (UInt32(macData[offset + 3]) & 0xFF)

        let modulus = UInt32(pow(10.0, Double(digits)))
        let value = truncated % modulus
        return String(format: "%0\(digits)d", value)
    }
}
