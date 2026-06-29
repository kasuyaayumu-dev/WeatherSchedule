import SwiftUI

/// 高さ固定・アイコン2つ（設定・検索）のみのトップバー。
/// Way Back ボタンは CalendarView 側のフローティングバーに移管。
struct TopBarView: View {
    var title: String
    var onSettings: () -> Void = {}
    var onSearch: () -> Void = {}
    
    // 高さを定数で固定し、スクロール時のガタつきを防ぐ
    static let fixedHeight: CGFloat = 56
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(title)
                .font(.title2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                iconButton("gearshape", label: "設定", action: onSettings)
                iconButton("magnifyingglass", label: "検索", action: onSearch)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: Self.fixedHeight)
        // 高さが絶対に変わらないよう固定
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(.systemGroupedBackground))
    }
    
    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
