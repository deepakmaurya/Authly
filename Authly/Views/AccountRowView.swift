import SwiftUI

struct AccountRowView: View {
    let account: TOTPAccount
    @State private var now: Date = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            issuerAvatar
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayTitle)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                if !account.displaySubtitle.isEmpty {
                    Text(account.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedCode)
                    .font(.system(.title3, design: .monospaced).weight(.medium))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                progressRing
            }
        }
        .padding(.vertical, 6)
        .onReceive(timer) { now = $0 }
    }

    private var formattedCode: String {
        let raw = account.currentCode(at: now)
        let mid = raw.index(raw.startIndex, offsetBy: raw.count / 2)
        return raw[..<mid] + " " + raw[mid...]
    }

    private var issuerAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(
                    colors: [color.opacity(0.85), color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .frame(width: 32, height: 32)
            Text(initial)
                .font(.system(.callout, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var initial: String {
        let s = account.displayTitle.first.map { String($0).uppercased() } ?? "?"
        return s
    }

    private var color: Color {
        let palette: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo, .red]
        let h = abs(account.displayTitle.hashValue)
        return palette[h % palette.count]
    }

    private var progressRing: some View {
        let progress = TOTPGenerator.progress(date: now, period: account.period)
        let remaining = TOTPGenerator.secondsRemaining(date: now, period: account.period)
        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: 1 - progress)
                .stroke(remaining <= 5 ? Color.red : Color.accentColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text("\(remaining)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(width: 22, height: 22)
    }
}
