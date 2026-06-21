import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ExportView: View {
    let accounts: [TOTPAccount]
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var saving = false
    @State private var status: String?

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(.title2.weight(.semibold))
                .lineLimit(1)

            Text(subtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let nsImage = qrImage {
                Image(nsImage: nsImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 280, height: 280)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 1)
                    )
            } else {
                ContentUnavailableView("Couldn't generate QR", systemImage: "exclamationmark.triangle")
            }

            HStack {
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    savePNG()
                } label: {
                    Label("Save PNG…", systemImage: "square.and.arrow.down")
                }
                .disabled(qrImage == nil)
                .buttonStyle(.borderedProminent)
            }

            if let status {
                Text(status).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 380, height: 480)
    }

    private var subtitle: String {
        accounts.count == 1
            ? "Scan with Google Authenticator or any otpauth-compatible app."
            : "Migration QR for \(accounts.count) accounts. Scan with Google Authenticator on your phone."
    }

    private var payload: String {
        accounts.count == 1
            ? OTPAuthURL.build(accounts[0])
            : MigrationParser.build(accounts)
    }

    private var qrImage: NSImage? { QRGenerator.generate(from: payload, size: 560) }

    private func savePNG() {
        guard let nsImage = qrImage,
              let tiff = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            status = "Failed to render PNG."
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(title.replacingOccurrences(of: "/", with: "_"))-qr.png"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try png.write(to: url)
                status = "Saved to \(url.lastPathComponent)"
            } catch {
                status = "Save failed: \(error.localizedDescription)"
            }
        }
    }
}
