import Foundation

/// Parses Google Authenticator's `otpauth-migration://offline?data=...` export
/// payload. Schema source: google/google-authenticator-android (proto definitions).
enum MigrationParser {

    static func parse(_ urlString: String) -> [TOTPAccount] {
        guard let comps = URLComponents(string: urlString),
              comps.scheme == "otpauth-migration",
              comps.host == "offline",
              let dataParam = comps.queryItems?.first(where: { $0.name == "data" })?.value
        else { return [] }

        let standardized = dataParam
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = standardized.padding(
            toLength: ((standardized.count + 3) / 4) * 4,
            withPad: "=", startingAt: 0)

        guard let payload = Data(base64Encoded: padded) else { return [] }
        return decodeMigrationPayload(payload)
    }

    private static func decodeMigrationPayload(_ data: Data) -> [TOTPAccount] {
        var reader = ProtoReader(data)
        var accounts: [TOTPAccount] = []

        while !reader.isAtEnd {
            guard let tag = reader.readTag() else { break }
            switch (tag.field, tag.wire) {
            case (1, 2):
                if let body = reader.readLengthDelimited(),
                   let acct = decodeOtpParameters(body) {
                    accounts.append(acct)
                }
            default:
                reader.skip(wire: tag.wire)
            }
        }
        return accounts
    }

    private static func decodeOtpParameters(_ data: Data) -> TOTPAccount? {
        var reader = ProtoReader(data)
        var secret = Data()
        var name = ""
        var issuer = ""
        var algorithmRaw: UInt64 = 1
        var digitsRaw: UInt64 = 1
        var typeRaw: UInt64 = 2

        while !reader.isAtEnd {
            guard let tag = reader.readTag() else { break }
            switch (tag.field, tag.wire) {
            case (1, 2):
                if let d = reader.readLengthDelimited() { secret = d }
            case (2, 2):
                if let d = reader.readLengthDelimited() { name = String(data: d, encoding: .utf8) ?? "" }
            case (3, 2):
                if let d = reader.readLengthDelimited() { issuer = String(data: d, encoding: .utf8) ?? "" }
            case (4, 0):
                if let v = reader.readVarint() { algorithmRaw = v }
            case (5, 0):
                if let v = reader.readVarint() { digitsRaw = v }
            case (6, 0):
                if let v = reader.readVarint() { typeRaw = v }
            default:
                reader.skip(wire: tag.wire)
            }
        }

        guard typeRaw == 2 else { return nil }       // skip HOTP
        guard !secret.isEmpty else { return nil }

        let algorithm: OTPAlgorithm
        switch algorithmRaw {
        case 2: algorithm = .sha256
        case 3: algorithm = .sha512
        default: algorithm = .sha1
        }
        let digits: Int = (digitsRaw == 2) ? 8 : 6

        var pathLabel = name
        var pathIssuer = issuer
        if pathIssuer.isEmpty, let colon = name.firstIndex(of: ":") {
            pathIssuer = String(name[..<colon])
            pathLabel = String(name[name.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        }

        return TOTPAccount(
            issuer: pathIssuer,
            label: pathLabel,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: 30
        )
    }

    /// Build an `otpauth-migration://offline?data=...` URL for a list of accounts.
    /// We re-encode using the same protobuf schema so a real Google Authenticator
    /// app could import it — useful for "Export to phone".
    static func build(_ accounts: [TOTPAccount]) -> String {
        var payload = Data()
        for acct in accounts {
            let body = encodeOtpParameters(acct)
            payload.append(contentsOf: encodeTag(field: 1, wire: 2))
            payload.append(contentsOf: encodeVarint(UInt64(body.count)))
            payload.append(body)
        }
        // version=1, batch_size=1, batch_index=0, batch_id=arbitrary
        payload.append(contentsOf: encodeTag(field: 2, wire: 0))
        payload.append(contentsOf: encodeVarint(1))
        payload.append(contentsOf: encodeTag(field: 3, wire: 0))
        payload.append(contentsOf: encodeVarint(1))
        payload.append(contentsOf: encodeTag(field: 4, wire: 0))
        payload.append(contentsOf: encodeVarint(0))
        payload.append(contentsOf: encodeTag(field: 5, wire: 0))
        payload.append(contentsOf: encodeVarint(UInt64.random(in: 0...UInt64(Int32.max))))

        let b64 = payload.base64EncodedString()
        var comps = URLComponents()
        comps.scheme = "otpauth-migration"
        comps.host = "offline"
        comps.queryItems = [URLQueryItem(name: "data", value: b64)]
        return comps.string ?? ""
    }

    private static func encodeOtpParameters(_ a: TOTPAccount) -> Data {
        var out = Data()
        // 1: secret
        out.append(contentsOf: encodeTag(field: 1, wire: 2))
        out.append(contentsOf: encodeVarint(UInt64(a.secret.count)))
        out.append(a.secret)
        // 2: name
        let name = a.issuer.isEmpty ? a.label : "\(a.issuer):\(a.label)"
        let nameBytes = Data(name.utf8)
        out.append(contentsOf: encodeTag(field: 2, wire: 2))
        out.append(contentsOf: encodeVarint(UInt64(nameBytes.count)))
        out.append(nameBytes)
        // 3: issuer
        if !a.issuer.isEmpty {
            let iss = Data(a.issuer.utf8)
            out.append(contentsOf: encodeTag(field: 3, wire: 2))
            out.append(contentsOf: encodeVarint(UInt64(iss.count)))
            out.append(iss)
        }
        // 4: algorithm
        let algoVal: UInt64 = {
            switch a.algorithm { case .sha1: return 1; case .sha256: return 2; case .sha512: return 3 }
        }()
        out.append(contentsOf: encodeTag(field: 4, wire: 0))
        out.append(contentsOf: encodeVarint(algoVal))
        // 5: digits (1=SIX, 2=EIGHT)
        out.append(contentsOf: encodeTag(field: 5, wire: 0))
        out.append(contentsOf: encodeVarint(a.digits == 8 ? 2 : 1))
        // 6: type = TOTP (2)
        out.append(contentsOf: encodeTag(field: 6, wire: 0))
        out.append(contentsOf: encodeVarint(2))
        return out
    }

    private static func encodeTag(field: Int, wire: Int) -> [UInt8] {
        encodeVarint(UInt64((field << 3) | wire))
    }

    private static func encodeVarint(_ value: UInt64) -> [UInt8] {
        var v = value
        var bytes: [UInt8] = []
        repeat {
            var byte = UInt8(v & 0x7F)
            v >>= 7
            if v != 0 { byte |= 0x80 }
            bytes.append(byte)
        } while v != 0
        return bytes
    }
}
