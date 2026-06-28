import SwiftUI

/// 1 か月分のセクション（月見出し + 暦に正確な 7 列グリッド）。
struct CalendarMonthView: View {
  var month: CalendarMonth
  var condition: (CalendarDay) -> WeatherCondition
  var isSelected: (CalendarDay) -> Bool
  var onTap: (CalendarDay) -> Void

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(month.firstDay.formatted(.dateTime.month(.wide).year()))
        .font(.title3.weight(.bold))
        .padding(.horizontal)
        .padding(.top, 18)

      LazyVGrid(columns: columns, spacing: 4) {
        ForEach(Array(month.cells.enumerated()), id: \.offset) { _, cell in
          if let day = cell {
            CalendarCellView(day: day, condition: condition(day), isSelected: isSelected(day)) {
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
