import SwiftUI

/// カレンダーの 1 日分セル。日付・天気アイコン・今日/選択インジケーターを描画。
struct CalendarCellView: View {
  var day: CalendarDay
  var condition: WeatherCondition
  var isSelected: Bool
  var action: () -> Void

  private var isToday: Bool { Calendar.current.isDateInToday(day.date) }
  private var isPast: Bool {
    Calendar.current.startOfDay(for: day.date) < Calendar.current.startOfDay(for: Date())
  }
  private var dayNumber: Int { Calendar.current.component(.day, from: day.date) }

  var body: some View {
    Button(action: action) {
      VStack(spacing: 5) {
        Text("\(dayNumber)")
          .font(.callout.weight(isToday ? .bold : .regular))
          .monospacedDigit()
          .foregroundStyle(numberColor)
          .frame(width: 30, height: 30)
          .background(indicator)

        Image(systemName: condition.symbol)
          .symbolRenderingMode(.multicolor)
          .font(.system(size: 16))
          .opacity(isPast ? 0.4 : 1)
          .contentTransition(.symbolEffect(.replace))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(day.date.formatted(.dateTime.month().day())), \(condition.label)")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  // 選択（青丸）が今日（赤丸）より優先。
  @ViewBuilder private var indicator: some View {
    if isSelected {
      Circle().fill(.blue)
    } else if isToday {
      Circle().fill(.red)
    }
  }

  private var numberColor: Color {
    if isSelected || isToday { return .white }
    return isPast ? .secondary : .primary
  }
}
