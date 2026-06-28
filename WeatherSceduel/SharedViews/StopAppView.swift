import SwiftUI

/// 起動フローの「stop app」画面。オフライン且つ保存データなしのときに表示する。
struct StopAppView: View {
  var message: String
  var onRetry: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.octagon.fill")
        .font(.system(size: 64))
        .foregroundStyle(.red)
        .accessibilityHidden(true)

      Text("起動できません")
        .font(.title2.weight(.bold))

      Text(message)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("再試行", systemImage: "arrow.clockwise", action: onRetry)
        .font(.headline)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .padding(.top, 4)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
  }
}
