import SwiftUI

/// カレンダーの 1 日分セル。表示モードに応じて天気・データ・予定を描画。
struct CalendarCellView: View {
    var day: CalendarDay
    var condition: WeatherCondition
    var forecast: ForecastResponse?
    var events: [ExternalCalendarEvent]
    var displayMode: CalendarDisplayMode
    var isFilteredOut: Bool
    var isSelected: Bool
    var action: () -> Void
    
    private var isToday: Bool { Calendar.current.isDateInToday(day.date) }
    private var isPast: Bool {
        Calendar.current.startOfDay(for: day.date) < Calendar.current.startOfDay(for: Date())
    }
    private var dayNumber: Int { Calendar.current.component(.day, from: day.date) }
    private var opacity: Double { isFilteredOut ? 0.22 : (isPast ? 0.45 : 1) }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(dayNumber)")
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(numberColor)
                    .frame(width: 30, height: 30)
                    .background(indicator)
                
                modeContent
                    .frame(height: 34)
                    .opacity(opacity)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    @ViewBuilder private var modeContent: some View {
        switch displayMode {
        case .weatherIcon:
            Image(systemName: condition.symbol)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 17))
                .contentTransition(.symbolEffect(.replace))
            
        case .weatherData:
            VStack(spacing: 2) {
                Label(rainText, systemImage: "drop.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.blue)
                Label(temperatureText, systemImage: "thermometer.medium")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.orange)
            }
            .font(.caption2.weight(.semibold))
            .minimumScaleFactor(0.75)
            .lineLimit(1)
            
        case .schedule:
            if let firstEvent = events.first {
                VStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(firstEvent.title)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .padding(.horizontal, 3)
            } else {
                Image(systemName: condition.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 15))
                    .opacity(0.55)
            }
        }
    }
    
    // 選択（青丸）が今日（赤丸）より優先。
    @ViewBuilder private var indicator: some View {
        if isSelected {
            Circle().fill(.blue)
        } else if isToday {
            Circle().fill(.red)
        }
    }
    
    private var rainText: String {
        if let percent = forecast?.aiPrediction.rainProbabilityPercent {
            return String(format: "%.0f%%", percent)
        }
        return "--%"
    }
    
    private var temperatureText: String {
        if let temperature = forecast?.aiPrediction.referencePastAverageTemp {
            return String(format: "%.0f°", temperature)
        }
        return "--°"
    }
    
    private var accessibilityText: String {
        var parts = [day.date.formatted(.dateTime.month().day()), condition.label]
        if !events.isEmpty {
            parts.append("予定 \(events.count)件")
        }
        return parts.joined(separator: ", ")
    }
    
    private var numberColor: Color {
        if isSelected || isToday { return .white }
        return isPast || isFilteredOut ? .secondary : .primary
    }
}
