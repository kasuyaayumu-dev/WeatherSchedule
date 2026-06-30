import UIKit

/// アプリ全体のHaptics管理。軽量なシングルトン。
enum HapticsManager {
    // ── ジェネレーターを使い回してレイテンシを下げる ──
    private static let light  = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid  = UIImpactFeedbackGenerator(style: .rigid)

    /// カレンダーの月が切り替わった時（軽め）
    static func monthChanged() {
        light.prepare()
        light.impactOccurred()
    }

    /// Way Back でカードが1年分切り替わった時（カチッ）
    static func wayBackYearChanged() {
        rigid.prepare()
        rigid.impactOccurred(intensity: 0.85)
    }

    /// Way Back を開く・閉じる時
    static func wayBackToggled() {
        medium.prepare()
        medium.impactOccurred()
    }
}
