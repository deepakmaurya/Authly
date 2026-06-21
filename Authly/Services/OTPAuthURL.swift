import Foundation

enum OTPAuthURL {
    /// Parse a standard `otpauth://totp/...` URL into an account.
    /// Returns nil for HOTP or unsupported schemes.
    static func parse(_ urlString: String) -> TOTPAccount? {
        guard let comps = URLComponents(string: urlString),
              comps.scheme == "otpauth",
              comps.host == "totp" else { return nil }

        let path = comps.path.hasPrefix("/") ? String(comps.path.dropFirst()) : comps.path
        let decodedPath = path.removingPercentEncoding ?? path

        var pathIssuer = ""
        var pathLabel = decodedPath
        if let colon = decodedPath.firstIndex(of: ":") {
            pathIssuer = String(decodedPath[..<colon])
            pathLabel = String(decodedPath[decodedPath.index(after: colon)...])
                .trimmingCharacters(in: .whitespaces)
        }

        let items = Dictionary(uniqueKeysWithValues:
            (comps.queryItems ?? []).compactMap { item -> (String, String)? in
                guard let v = item.value else { return nil }
                return (item.name.lowercased(), v)
            })

        guard let secretStr = items["secret"],
              let secret = Base32.decode(secretStr) else { return nil }

        let issuer = items["issuer"] ?? pathIssuer
        let digits = Int(items["digits"] ?? "6") ?? 6
        let period = Int(items["period"] ?? "30") ?? 30
        let algo = OTPAlgorithm(rawValue: (items["algorithm"] ?? "SHA1").uppercased()) ?? .sha1

        return TOTPAccount(
            issuer: issuer,
            label: pathLabel,
            secret: secret,
            algorithm: algo,
            digits: digits,
            period: period
        )
    }

    /// Build a standard `otpauth://totp/...` URL for export.
    static func build(_ account: TOTPAccount) -> String {
        let secretB32 = Base32.encode(account.secret)
        var pathPart = ""
        if !account.issuer.isEmpty {
            pathPart = account.issuer + ":" + account.label
        } else {
            pathPart = account.label
        }
        let encodedPath = pathPart.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pathPart

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "secret", value: secretB32),
            URLQueryItem(name: "algorithm", value: account.algorithm.rawValue),
            URLQueryItem(name: "digits", value: String(account.digits)),
            URLQueryItem(name: "period", value: String(account.period))
        ]
        if !account.issuer.isEmpty {
            queryItems.append(URLQueryItem(name: "issuer", value: account.issuer))
        }
        var comps = URLComponents()
        comps.scheme = "otpauth"
        comps.host = "totp"
        comps.path = "/" + encodedPath
        comps.queryItems = queryItems
        return comps.string ?? ""
    }
}
