import SwiftUI

struct AccountListView: View {
    @EnvironmentObject var store: AccountStore
    let query: String
    @Binding var selection: TOTPAccount.ID?

    var body: some View {
        let items = store.filtered(query)
        List(selection: $selection) {
            ForEach(items) { acct in
                AccountRowView(account: acct)
                    .tag(acct.id)
                    .contextMenu {
                        Button("Copy Code") { copyCode(acct) }
                        Button("Export QR…") { /* selection handled in parent */ }
                        Divider()
                        Button("Delete", role: .destructive) { store.delete(acct) }
                    }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "No Accounts" : "No Matches",
                    systemImage: query.isEmpty ? "lock.shield" : "magnifyingglass",
                    description: Text(query.isEmpty
                        ? "Add an account using the + button in the toolbar."
                        : "Try a different search term.")
                )
            }
        }
    }

    private func copyCode(_ acct: TOTPAccount) {
        let code = acct.currentCode()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(code, forType: .string)
    }
}
