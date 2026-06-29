import Foundation

/// カレンダー上の 1 日分のデータ。天気・降水確率はモックを返す。
struct CalendarDay: Identifiable, Hashable {
    var date: Date
    var id: Date { date }
    
    var condition: WeatherCondition { .mock(for: date) }
    var rainProbability: Int { MockWeather.rainProbability(for: date) }
}

/// 1 か月分のグリッドデータ。
/// `leadingBlanks` は 1 日が始まる曜日までの空白セル数（暦に合わせる）。
struct CalendarMonth: Identifiable, Hashable {
    var firstDay: Date
    var leadingBlanks: Int
    var days: [CalendarDay]
    var id: Date { firstDay }
    
    /// 先頭の空白 + 実日付を並べたグリッドセル列（nil は空白）。
    var cells: [CalendarDay?] {
        Array(repeating: nil, count: leadingBlanks) + days.map { Optional($0) }
    }
}

// MARK: - モックデータ

extension WeatherCondition {
    /// 日付から決定論的に天気を割り当てる（プレビューでも安定する）。
    static func mock(for date: Date) -> WeatherCondition {
        let all = WeatherCondition.allCases
        return all[dayOrdinal(for: date) % all.count]
    }
}

enum MockWeather {
    static func rainProbability(for date: Date) -> Int {
        let base: Int
        switch WeatherCondition.mock(for: date) {
        case .sunny: base = 5
        case .partlyCloudy: base = 20
        case .cloudy: base = 40
        case .rainy: base = 75
        case .stormy: base = 90
        case .snowy: base = 65
        }
        return min(100, base + dayOrdinal(for: date) % 10)
    }
}

/// 紀元からの通算日数。モックのシード兼日付比較に使う。
func dayOrdinal(for date: Date) -> Int {
    Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
}
