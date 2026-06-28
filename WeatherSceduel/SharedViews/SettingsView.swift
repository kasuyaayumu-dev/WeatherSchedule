import SwiftUI

/// 歯車アイコンから開く設定画面。キャッシュの保存範囲を調整する（土台）。
struct SettingsView: View {
  @AppStorage(CacheSettings.pastYearsKey) private var pastYears = CacheSettings.defaultPastYears
  @AppStorage(CacheSettings.futureMonthsKey) private var futureMonths = CacheSettings.defaultFutureMonths
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("保存範囲") {
          Stepper("過去 \(pastYears) 年分", value: $pastYears, in: 0...10)
          Stepper("未来 \(futureMonths) ヶ月分", value: $futureMonths, in: 1...60)
        }
        Section {
          Text("設定した範囲外のキャッシュは、次回起動時に自動で削除されます。")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("設定")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("完了") { dismiss() }
        }
      }
    }
  }
}
