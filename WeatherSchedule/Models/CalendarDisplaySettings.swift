import SwiftUI

enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case weatherIcon
    case weatherData
    case schedule
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .weatherIcon: "アイコン"
        case .weatherData: "データ"
        case .schedule: "予定"
        }
    }
    
    var symbol: String {
        switch self {
        case .weatherIcon: "sun.max.fill"
        case .weatherData: "chart.bar.fill"
        case .schedule: "calendar"
        }
    }
}

enum CalendarWeatherFilter: String, CaseIterable, Identifiable {
    case all
    case sunny
    case cool
    case rainy
    case snowy
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: "すべて"
        case .sunny: "Sunny"
        case .cool: "Cool"
        case .rainy: "Rainy"
        case .snowy: "Snowy"
        }
    }
    
    var symbol: String {
        switch self {
        case .all: "line.3.horizontal.decrease.circle"
        case .sunny: "sun.max.fill"
        case .cool: "cloud.fill"
        case .rainy: "cloud.rain.fill"
        case .snowy: "snowflake"
        }
    }
    
    func matches(condition: WeatherCondition) -> Bool {
        switch self {
        case .all:
            true
        case .sunny:
            condition == .sunny || condition == .partlyCloudy
        case .cool:
            condition == .cloudy
        case .rainy:
            condition == .rainy || condition == .stormy
        case .snowy:
            condition == .snowy
        }
    }
}

enum CalendarDisplaySettings {
    static let modeKey = "calendar.display.mode"
    static let weatherFilterKey = "calendar.weather.filter"
    static let defaultMode = CalendarDisplayMode.weatherIcon.rawValue
    static let defaultWeatherFilter = CalendarWeatherFilter.all.rawValue
}
