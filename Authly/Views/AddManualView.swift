import SwiftUI

struct AddManualView: View {
    @EnvironmentObject var store: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var issuer = ""
    @State private var label = ""
    @State private var secret = ""
    @State private var algorithm: OTPAlgorithm = .sha1
    @State private var digits = 6
    @State private var period = 30
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Account") {
                    TextField("Issuer (e.g. Google, GitHub)", text: $issuer)
                    TextField("Account (e.g. you@example.com)", text: $label)
                }
                Section("Secret") {
                    TextField("Base32 secret", text: $secret)
                        .textContentType(.password)
                        .font(.system(.body, design: .monospaced))
                }
                Section("Advanced") {
                    Picker("Algorithm", selection: $algorithm) {
                        Text("SHA1").tag(OTPAlgorithm.sha1)
                        Text("SHA256").tag(OTPAlgorithm.sha256)
                        Text("SHA512").tag(OTPAlgorithm.sha512)
                    }
                    Stepper("Digits: \(digits)", value: $digits, in: 6...8)
                    Stepper("Period: \(period)s", value: $period, in: 15...120, step: 15)
                }
                if let error {
                    Text(error).foregroundStyle(.red).font(.callout)
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add Account") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(secret.trimmingCharacters(in: .whitespaces).isEmpty
                              || (issuer.isEmpty && label.isEmpty))
            }
            .padding()
        }
        .frame(width: 480, height: 460)
    }

    private func save() {
        guard let secretData = Base32.decode(secret) else {
            error = "Secret is not valid Base32."
            return
        }
        let acct = TOTPAccount(
            issuer: issuer.trimmingCharacters(in: .whitespaces),
            label: label.trimmingCharacters(in: .whitespaces),
            secret: secretData,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
        store.add(acct)
        dismiss()
    }
}
