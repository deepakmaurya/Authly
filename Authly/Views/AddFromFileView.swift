import SwiftUI
import UniformTypeIdentifiers

struct AddFromFileView: View {
    @EnvironmentObject var store: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var importing = false
    @State private var status: String?
    @State private var imported = 0

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Import QR Codes from File")
                .font(.title2.weight(.semibold))

            Text("Select one or more images containing QR codes from Google Authenticator's \"Transfer accounts\" export, or any standard otpauth:// QR.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)

            Button {
                importing = true
            } label: {
                Label("Choose Files…", systemImage: "folder")
                    .frame(minWidth: 160)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            if let status {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 480, height: 380)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.image, .png, .jpeg, .heic, .tiff],
            allowsMultipleSelection: true
        ) { result in
            handle(result)
        }
    }

    private func handle(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let err):
            status = "Failed: \(err.localizedDescription)"
        case .success(let urls):
            var added = 0
            var scanned = 0
            for url in urls {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let payloads = QRImageScanner.scanFile(at: url)
                scanned += payloads.count
                for payload in payloads {
                    added += store.ingestPayload(payload)
                }
            }
            imported += added
            if scanned == 0 {
                status = "No QR codes found in the selected file(s)."
            } else {
                status = "Imported \(added) account\(added == 1 ? "" : "s") from \(scanned) QR code\(scanned == 1 ? "" : "s")."
            }
        }
    }
}
