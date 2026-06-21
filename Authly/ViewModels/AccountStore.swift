import Foundation
import Combine

@MainActor
final class AccountStore: ObservableObject {
    @Published var accounts: [TOTPAccount] = []
    @Published var lastError: String?

    private let keychain = KeychainService()

    init() { load() }

    func load() {
        do {
            guard let data = try keychain.load() else { return }
            let decoded = try JSONDecoder().decode([TOTPAccount].self, from: data)
            self.accounts = decoded
        } catch {
            self.lastError = "Failed to load vault: \(error.localizedDescription)"
        }
    }

    func persist() {
        do {
            let data = try JSONEncoder().encode(accounts)
            try keychain.save(data)
        } catch {
            self.lastError = "Failed to save vault: \(error.localizedDescription)"
        }
    }

    func add(_ account: TOTPAccount) {
        if let existing = accounts.firstIndex(where: {
            $0.issuer == account.issuer &&
            $0.label == account.label &&
            $0.secret == account.secret
        }) {
            accounts[existing] = account
        } else {
            accounts.append(account)
        }
        persist()
    }

    func add(_ list: [TOTPAccount]) -> Int {
        var added = 0
        for a in list {
            if !accounts.contains(where: {
                $0.issuer == a.issuer && $0.label == a.label && $0.secret == a.secret
            }) {
                accounts.append(a)
                added += 1
            }
        }
        persist()
        return added
    }

    func update(_ account: TOTPAccount) {
        guard let idx = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[idx] = account
        persist()
    }

    func delete(_ account: TOTPAccount) {
        accounts.removeAll { $0.id == account.id }
        persist()
    }

    func filtered(_ query: String) -> [TOTPAccount] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return accounts }
        return accounts.filter {
            $0.issuer.lowercased().contains(q) || $0.label.lowercased().contains(q)
        }
    }

    /// Try every parser strategy on a raw QR/URL payload. Returns accounts ingested.
    @discardableResult
    func ingestPayload(_ payload: String) -> Int {
        if payload.hasPrefix("otpauth-migration://") {
            let list = MigrationParser.parse(payload)
            return add(list)
        }
        if payload.hasPrefix("otpauth://") {
            if let acct = OTPAuthURL.parse(payload) {
                add(acct)
                return 1
            }
        }
        return 0
    }
}
