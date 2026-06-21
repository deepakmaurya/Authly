import SwiftUI

struct AddFromCameraView: View {
    @EnvironmentObject var store: AccountStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = CameraScanner()
    @State private var status: String?
    @State private var imported = 0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                CameraPreviewView(session: scanner.session)
                    .frame(width: 480, height: 320)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 1)
                    )

                if !scanner.isAuthorized {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill").font(.system(size: 32))
                        Text("Waiting for camera access…")
                    }
                    .foregroundStyle(.white)
                }

                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 220, height: 220)
                    .shadow(color: .accentColor.opacity(0.4), radius: 8)
            }

            Text("Hold a QR code in front of the camera.")
                .foregroundStyle(.secondary)

            if let status {
                Text(status).font(.callout)
            }

            HStack {
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text("Imported: \(imported)")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 540, height: 460)
        .onAppear { scanner.start() }
        .onDisappear { scanner.stop() }
        .onChange(of: scanner.lastPayload) { _, payload in
            guard let payload else { return }
            let added = store.ingestPayload(payload)
            imported += added
            status = added > 0
                ? "Added \(added) account\(added == 1 ? "" : "s")."
                : "QR detected, but it isn't a recognized otpauth code."
        }
        .onChange(of: scanner.error) { _, err in
            if let err { status = err }
        }
    }
}
