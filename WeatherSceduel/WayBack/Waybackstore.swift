import Foundation
import Observation
import SwiftUI

// MARK: - モックデータ

/// 1日分の過去気象データ（スタブ）。
struct HistoricalDayWeather: Identifiable {
  var id: String { "\(year)-\(month)-\(day)" }
  var year: Int
  var month: Int
  var day: Int
  var condition: WeatherCondition
  var temperatureCelsius: Double
  var rainProbabilityPercent: Double
}

/// 1ヶ月分の過去気象サマリー（カードのヘッダー用）。
struct HistoricalMonthSummary {
  var year: Int
  var month: Int
  var avgTemperatureCelsius: Double
  var dominantCondition: WeatherCondition
  var rainyDays: Int
  var sunnyDays: Int
}

enum HistoricalDataStub {
  /// 決定論的なモックデータを生成する。
  static func monthSummary(year: Int, month: Int) -> HistoricalMonthSummary {
    let seed = year * 12 + month
    let conditions = WeatherCondition.allCases
    let dominant = conditions[seed % conditions.count]
    let baseTemp = 15.0 + Double(month % 12) * 1.3 - Double((year - 2020) % 3) * 0.5
    return HistoricalMonthSummary(
      year: year,
      month: month,
      avgTemperatureCelsius: (baseTemp * 10).rounded() / 10,
      dominantCondition: dominant,
      rainyDays: (seed % 10) + 3,
      sunnyDays: (seed % 8) + 5
    )
  }

  static func dayWeather(year: Int, month: Int, day: Int) -> HistoricalDayWeather {
    let seed = year * 366 + month * 31 + day
    let condition = WeatherCondition.allCases[seed % WeatherCondition.allCases.count]
    let temp = 10.0 + Double(seed % 20) + Double(month) * 1.1
    return HistoricalDayWeather(
      year: year,
      month: month,
      day: day,
      condition: condition,
      temperatureCelsius: (temp * 10).rounded() / 10,
      rainProbabilityPercent: Double((seed * 17) % 100)
    )
  }
}

// MARK: - Store

@MainActor
@Observable
final class WayBackStore {
  /// Way Backモードが表示されているか。
  var isPresented = false

  /// 現在選択中の基準年（一番手前のカード）。
  var selectedYear: Int = Calendar.current.component(.year, from: Date()) - 1

  /// ドラッグ中の移動量（アニメーション計算に使用）。
  var dragOffset: CGFloat = 0

  /// スワイプ操作のトランジション中か。
  var isTransitioning = false

  /// カレンダーから引き継ぐ「選択中の月日」。
  var referenceMonth: Int
  var referenceDay: Int?

  /// 表示するカードの年リスト（手前から奥へ）。
  var cardYears: [Int] {
    (0..<visibleCardCount).map { selectedYear - $0 }
  }

  let visibleCardCount = 5
  let minYear = 2000
  var maxYear: Int { Calendar.current.component(.year, from: Date()) - 1 }

  init() {
    let now = Date()
    let cal = Calendar.current
    referenceMonth = cal.component(.month, from: now)
    referenceDay = cal.component(.day, from: now)
  }

  // MARK: - 操作

  func open(referenceDate: Date? = nil) {
    if let date = referenceDate {
      let cal = Calendar.current
      referenceMonth = cal.component(.month, from: date)
      referenceDay = cal.component(.day, from: date)
    }
    selectedYear = maxYear
    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
      isPresented = true
    }
  }

  func close() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
      isPresented = false
      dragOffset = 0
    }
  }

  /// スワイプ完了時に年を進める（手前へ）または戻す（奥へ）。
  func commitSwipe(velocity: CGFloat) {
    guard !isTransitioning else { return }

    let threshold: CGFloat = 60
    let shouldGoBack = dragOffset > threshold || velocity > 400   // 奥へ（古い年）
    let shouldGoForward = dragOffset < -threshold || velocity < -400 // 手前へ（新しい年）

    if shouldGoBack, selectedYear > minYear {
      isTransitioning = true
      withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
        selectedYear -= 1
        dragOffset = 0
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
        self.isTransitioning = false
      }
    } else if shouldGoForward, selectedYear < maxYear {
      isTransitioning = true
      withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
        selectedYear += 1
        dragOffset = 0
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
        self.isTransitioning = false
      }
    } else {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
        dragOffset = 0
      }
    }
  }

  /// 年を直接選択する（年リストのタップ用）。
  func selectYear(_ year: Int) {
    guard year >= minYear, year <= maxYear, !isTransitioning else { return }
    isTransitioning = true
    withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
      selectedYear = year
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
      self.isTransitioning = false
    }
  }

  /// フロントカードの月サマリー。
  func frontCardSummary() -> HistoricalMonthSummary {
    HistoricalDataStub.monthSummary(year: selectedYear, month: referenceMonth)
  }

  /// 日付指定のデータ（referenceDay がある場合）。
  func frontCardDayWeather() -> HistoricalDayWeather? {
    guard let day = referenceDay else { return nil }
    return HistoricalDataStub.dayWeather(year: selectedYear, month: referenceMonth, day: day)
  }
}
