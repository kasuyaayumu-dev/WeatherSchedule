import SwiftUI

/// 1 か月分のセクション（月見出し + 暦に正確な 7 列グリッド）。
///
/// ### フィルターハイライト方式（v2）
/// CalendarWeatherFilter.all の場合は isFilteredOut を常に false にし、
/// ハイライトリングを出さない（"すべて表示" = 強調なし）。
/// それ以外のフィルターが選択されているとき、
/// 一致しないセルは opacity + saturation で背景に引かせ、
/// 一致するセルは CalendarCellView 内のグローリングで浮き上がらせる。
struct CalendarMonthView: View {
    var month: CalendarMonth
    var condition: (CalendarDay) -> WeatherCondition
    var forecast: (CalendarDay) -> ForecastResponse?
    var events: (CalendarDay) -> [ExternalCalendarEvent]
    var displayMode: CalendarDisplayMode
    var weatherFilter: CalendarWeatherFilter
    var isSelected: (CalendarDay) -> Bool
    var onTap: (CalendarDay) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    /// フィルターが "すべて" 以外に設定されているか。
    private var isFilterActive: Bool { weatherFilter != .all }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(month.firstDay.formatted(.dateTime.month(.wide).year()))
                .font(.title3.weight(.bold))
                .padding(.horizontal)
                .padding(.top, 18)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(month.cells.enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        let resolvedCondition = condition(day)

                        // フィルターが有効なとき → 一致しないセルを isFilteredOut=true
                        // フィルターが "すべて" のとき → 常に isFilteredOut=false（ハイライトなし）
                        let filteredOut = isFilterActive
                            ? !weatherFilter.matches(condition: resolvedCondition)
                            : false

                        CalendarCellView(
                            day: day,
                            condition: resolvedCondition,
                            forecast: forecast(day),
                            events: events(day),
                            displayMode: displayMode,
                            isFilteredOut: filteredOut,
                            isSelected: isSelected(day)
                        ) {
                            onTap(day)
                        }
                    } else {
                        Color.clear
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
