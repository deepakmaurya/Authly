import SwiftUI

struct AccountDetailView: View {
    @EnvironmentObject var store: AccountStore
    let account: TOTPAccount

    @State private var now = Date()
    @State private var copied = false
    @State private var showExport = false
    @State private var confirmingDelete = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(account.displayTitle)
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                if !account.displaySubtitle.isEmpty {
                    Text(account.displaySubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 32)

            codeCard

            HStack(spacing: 12) {
                Button {
                    copyCode()
                } label: {
                    Label(copied ? "Copied" : "Copy Code", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(minWidth: 120)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button {
                    showExport = true
                } label: {
                    Label("Export QR", systemImage: "qrcode")
                        .frame(minWidth: 120)
                }
                .controlSize(.large)

                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(minWidth: 120)
                }
                .controlSize(.large)
            }

            metadataPanel

            Spacer()
        }
        .padding(32)
        .onReceive(timer) { now = $0 }
        .sheet(isPresented: $showExport) {
            ExportView(accounts: [account], title: account.displayTitle)
        }
        .confirmationDialog(
            "Delete \(account.displayTitle)?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { store.delete(account) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the account from Authly. Your account on \(account.displayTitle) is unaffected.")
        }
    }

    private var codeCard: some View {
        VStack(spacing: 14) {
            Text(formattedCode)
                .font(.system(size: 56, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                ProgressView(value: 1 - TOTPGenerator.progress(date: now, period: account.period))
                    .progressViewStyle(.linear)
                    .tint(remaining <= 5 ? .red : .accentColor)
                    .frame(maxWidth: 280)
                Text("\(remaining)s")
                    .monospacedDigit()
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
            }
        }
        .padding(.vertical, 28)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.background.secondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }

    private var metadataPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("Algorithm", account.algorithm.rawValue)
            row("Digits", "\(account.digits)")
            row("Period", "\(account.period)s")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 420, alignment: .leading)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k); Spacer(); Text(v).foregroundStyle(.primary)
        }
    }

    private var remaining: Int {
        TOTPGenerator.secondsRemaining(date: now, period: account.period)
    }

    private var formattedCode: String {
        let raw = account.currentCode(at: now)
        let mid = raw.index(raw.startIndex, offsetBy: raw.count / 2)
        return raw[..<mid] + " " + raw[mid...]
    }

    private func copyCode() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(account.currentCode(at: now), forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copied = false }
        }
    }
}
