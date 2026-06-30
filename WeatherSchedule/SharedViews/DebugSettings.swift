import Foundation
import SwiftUI

// MARK: - デバッグ設定

/// アプリ全体のデバッグ・開発用フラグをまとめる名前空間。
/// UserDefaults に永続化するため、シミュレーター再起動後も設定が残る。
enum DebugSettings {
    // MARK: UserDefaults キー

    private static let mockModeKey        = "debug.mockMode"
    private static let miniPlayerKey      = "ui.miniPlayerEnabled"

    // MARK: モックモード

    /// true のとき API 通信をスキップし、内部生成データを使う。
    static var isMockModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: mockModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: mockModeKey) }
    }

    // MARK: ミニプレーヤー

    /// true のとき、モーダルを下スワイプすると下部バーに縮小表示する。
    static var isMiniPlayerEnabled: Bool {
        get {
            // デフォルト true（初回起動時から有効）
            if UserDefaults.standard.object(forKey: miniPlayerKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: miniPlayerKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: miniPlayerKey) }
    }

    // MARK: AppStorage キー（View 側で直接使う）

    static let mockModeAppStorageKey   = mockModeKey
    static let miniPlayerAppStorageKey = miniPlayerKey
}

// MARK: - DebugSettingsView（SettingsView に埋め込む用）

struct DebugSettingsSection: View {
    @AppStorage(DebugSettings.mockModeAppStorageKey)   private var mockMode   = false
    @AppStorage(DebugSettings.miniPlayerAppStorageKey) private var miniPlayer = true

    var body: some View {
        Section {
            Toggle(isOn: $miniPlayer) {
                Label("ミニプレーヤーバー", systemImage: "dock.rectangle")
            }
        } header: {
            Text("表示")
        } footer: {
            Text("モーダルを下スワイプすると画面下部に縮小表示します。")
        }

        Section {
            Toggle(isOn: $mockMode) {
                Label("モックモード", systemImage: "hammer.fill")
                    .foregroundStyle(mockMode ? .orange : .primary)
            }
        } header: {
            Text("開発者向け")
        } footer: {
            Text("有効にすると API 通信をスキップし、内部生成データを使います。実機テストに便利です。")
        }
    }
}
