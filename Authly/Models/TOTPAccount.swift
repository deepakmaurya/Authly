import Foundation

struct TOTPAccount: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var issuer: String
    var label: String          // typically the user's email/username
    var secret: Data           // raw bytes (decoded from Base32)
    var algorithm: OTPAlgorithm = .sha1
    var digits: Int = 6
    var period: Int = 30
    var createdAt: Date = Date()

    var displayTitle: String {
        issuer.isEmpty ? label : issuer
    }

    var displaySubtitle: String {
        issuer.isEmpty ? "" : label
    }

    func currentCode(at date: Date = Date()) -> String {
        TOTPGenerator.code(secret: secret, date: date, digits: digits, period: period, algorithm: algorithm)
    }
}
