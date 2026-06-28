import SwiftUI

/// 天気の状態。SF Symbols と表示色を一元管理する。
enum WeatherCondition: String, CaseIterable, Hashable {
  case sunny
  case partlyCloudy
  case cloudy
  case rainy
  case stormy

  var symbol: String {
    switch self {
    case .sunny: "sun.max.fill"
    case .partlyCloudy: "cloud.sun.fill"
    case .cloudy: "cloud.fill"
    case .rainy: "cloud.rain.fill"
    case .stormy: "cloud.bolt.rain.fill"
    }
  }

  var label: String {
    switch self {
    case .sunny: "Sunny"
    case .partlyCloudy: "Partly Cloudy"
    case .cloudy: "Cloudy"
    case .rainy: "Rainy"
    case .stormy: "Stormy"
    }
  }

  var tint: Color {
    switch self {
    case .sunny: .orange
    case .partlyCloudy: .yellow
    case .cloudy: .gray
    case .rainy: .blue
    case .stormy: .indigo
    }
  }

  /// API の降水確率(%)から天気を判定する。
  static func from(rainProbability percent: Double) -> WeatherCondition {
    switch percent {
    case ..<10: .sunny
    case ..<30: .partlyCloudy
    case ..<55: .cloudy
    case ..<80: .rainy
    default: .stormy
    }
  }
}
