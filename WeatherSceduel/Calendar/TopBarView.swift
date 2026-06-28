import SwiftUI

/// 画面上部の月見出しとアクションメニュー。
/// ★ onWayBack クロージャを追加。時計アイコンに接続済み。
struct TopBarView: View {
  var title: String
  var onSettings: () -> Void = {}
  // ★ Way Back ボタンのコールバック
  var onWayBack: () -> Void = {}

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.largeTitle.weight(.bold))
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Spacer(minLength: 8)

      HStack(spacing: 16) {
        // ★ Way Back へ接続
        actionButton("clock.arrow.circlepath", label: "Way Back", action: onWayBack)
        actionButton("gearshape", label: "Settings", action: onSettings)
        actionButton("magnifyingglass", label: "Search") {}
        actionButton("plus", label: "Add Event") {}
      }
      .font(.title3)
      .foregroundStyle(.tint)
    }
    .padding(.horizontal)
    .padding(.top, 8)
  }

  private func actionButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .frame(width: 30, height: 30)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}
