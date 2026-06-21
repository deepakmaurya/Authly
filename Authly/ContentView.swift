import SwiftUI

enum AddSheet: Identifiable {
    case file, camera, manual, exportAll, exportOne(TOTPAccount)
    var id: String {
        switch self {
        case .file: return "file"
        case .camera: return "camera"
        case .manual: return "manual"
        case .exportAll: return "exportAll"
        case .exportOne(let a): return "exportOne-\(a.id)"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: AccountStore
    @State private var search = ""
    @State private var sheet: AddSheet?
    @State private var selection: TOTPAccount.ID?

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 260, ideal: 320, max: 420)
        } detail: {
            detail
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .file:    AddFromFileView()
            case .camera:  AddFromCameraView()
            case .manual:  AddManualView()
            case .exportAll: ExportView(accounts: store.accounts, title: "Export All Accounts")
            case .exportOne(let a): ExportView(accounts: [a], title: a.displayTitle)
            }
        }
        .toolbar { toolbar }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            AccountListView(query: search, selection: $selection)
        }
        .searchable(text: $search, placement: .sidebar, prompt: "Search accounts")
    }

    @ViewBuilder
    private var detail: some View {
        if let id = selection,
           let account = store.accounts.first(where: { $0.id == id }) {
            AccountDetailView(account: account)
        } else {
            ContentUnavailableView(
                "Select an account",
                systemImage: "lock.shield",
                description: Text("Or add one with the + button.")
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    sheet = .camera
                } label: { Label("Scan with Camera", systemImage: "camera") }
                Button {
                    sheet = .file
                } label: { Label("Import QR from File…", systemImage: "photo") }
                Button {
                    sheet = .manual
                } label: { Label("Enter Manually", systemImage: "pencil") }
                Divider()
                Button {
                    sheet = .exportAll
                } label: { Label("Export All as QR…", systemImage: "square.and.arrow.up") }
                .disabled(store.accounts.isEmpty)
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
}
