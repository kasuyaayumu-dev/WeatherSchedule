import SwiftUI

/// 天気の状態。SF Symbols と表示色を一元管理する。
enum WeatherCondition: String, CaseIterable, Hashable {
    case sunny
    case partlyCloudy
    case cloudy
    case rainy
    case stormy
    case snowy
    
    var symbol: String {
        switch self {
        case .sunny: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rainy: "cloud.rain.fill"
        case .stormy: "cloud.bolt.rain.fill"
        case .snowy: "snowflake"
        }
    }
    
    var label: String {
        switch self {
        case .sunny: "Sunny"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rainy: "Rainy"
        case .stormy: "Stormy"
        case .snowy: "Snowy"
        }
    }
    
    var tint: Color {
        switch self {
        case .sunny: .orange
        case .partlyCloudy: .yellow
        case .cloudy: .gray
        case .rainy: .blue
        case .stormy: .indigo
        case .snowy: .cyan
        }
    }
    
    /// API の降水確率(%)から天気を判定する。
    static func from(rainProbability percent: Double) -> WeatherCondition {
        from(rainProbability: percent, temperature: nil)
    }
    
    /// 気温が低く降水確率が高い日は Snowy として扱う。
    static func from(rainProbability percent: Double, temperature: Double?) -> WeatherCondition {
        if let temperature, temperature <= 2, percent >= 35 {
            return .snowy
        }
        
        switch percent {
        case ..<10: return .sunny
        case ..<30: return .partlyCloudy
        case ..<55: return .cloudy
        case ..<80: return .rainy
        default: return .stormy
        }
    }
}
