import SwiftUI

/// 歯車アイコンから開く設定画面。保存範囲、表示モード、カレンダー連携を調整する。
struct SettingsView: View {
    var externalCalendar: ExternalCalendarStore
    var onRefreshExternalCalendar: () -> Void
    
    @AppStorage(CacheSettings.pastYearsKey) private var pastYears = CacheSettings.defaultPastYears
    @AppStorage(CacheSettings.futureMonthsKey) private var futureMonths = CacheSettings.defaultFutureMonths
    @AppStorage(CalendarDisplaySettings.modeKey) private var displayModeRawValue = CalendarDisplaySettings.defaultMode
    @AppStorage(CalendarDisplaySettings.weatherFilterKey) private var weatherFilterRawValue = CalendarDisplaySettings.defaultWeatherFilter
    @Environment(\.dismiss) private var dismiss
    
    private var displayModeBinding: Binding<CalendarDisplayMode> {
        Binding(
            get: { CalendarDisplayMode(rawValue: displayModeRawValue) ?? .weatherIcon },
            set: { displayModeRawValue = $0.rawValue }
        )
    }
    
    private var weatherFilterBinding: Binding<CalendarWeatherFilter> {
        Binding(
            get: { CalendarWeatherFilter(rawValue: weatherFilterRawValue) ?? .all },
            set: { weatherFilterRawValue = $0.rawValue }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("表示モード") {
                    Picker("表示", selection: displayModeBinding) {
                        ForEach(CalendarDisplayMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.symbol)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("天気フィルター", selection: weatherFilterBinding) {
                        ForEach(CalendarWeatherFilter.allCases) { filter in
                            Label(filter.title, systemImage: filter.symbol)
                                .tag(filter)
                        }
                    }
                }
                
                Section("カレンダー連携") {
                    HStack {
                        Label(calendarStatusText, systemImage: calendarStatusSymbol)
                            .foregroundStyle(calendarStatusColor)
                        Spacer()
                    }
                    
                    Button {
                        onRefreshExternalCalendar()
                    } label: {
                        Label("カレンダーアプリの予定を読み込む", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(externalCalendar.accessState == .requesting)
                    
                    Text("予定モードでは、端末のカレンダーに入っている予定タイトルを日付セルに表示します。読み込みにはフルアクセス権限が必要です。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
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
    
    private var calendarStatusText: String {
        switch externalCalendar.accessState {
        case .notRequested: "未連携"
        case .requesting: "権限を確認中"
        case .granted: "連携済み"
        case .denied: "アクセスが許可されていません"
        case .unavailable: "この端末では利用できません"
        }
    }
    
    private var calendarStatusSymbol: String {
        switch externalCalendar.accessState {
        case .notRequested, .requesting: "calendar.badge.clock"
        case .granted: "checkmark.circle.fill"
        case .denied, .unavailable: "exclamationmark.triangle.fill"
        }
    }
    
    private var calendarStatusColor: Color {
        switch externalCalendar.accessState {
        case .granted: .green
        case .denied, .unavailable: .orange
        case .notRequested, .requesting: .secondary
        }
    }
}
