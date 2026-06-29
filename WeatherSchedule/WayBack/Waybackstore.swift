import Foundation
import Observation
import SwiftUI

// MARK: - モックデータ

struct HistoricalDayWeather: Identifiable {
    var id: String { "\(year)-\(month)-\(day)" }
    var year: Int; var month: Int; var day: Int
    var condition: WeatherCondition
    var temperatureCelsius: Double
    var rainProbabilityPercent: Double
}

struct HistoricalMonthSummary {
    var year: Int; var month: Int
    var avgTemperatureCelsius: Double
    var dominantCondition: WeatherCondition
    var rainyDays: Int; var sunnyDays: Int
}

enum HistoricalDataStub {
    static func monthSummary(year: Int, month: Int) -> HistoricalMonthSummary {
        let seed = year * 12 + month
        let dominant = WeatherCondition.allCases[seed % WeatherCondition.allCases.count]
        let baseTemp = 15.0 + Double(month % 12) * 1.3 - Double((year - 2020) % 3) * 0.5
        return HistoricalMonthSummary(
            year: year, month: month,
            avgTemperatureCelsius: (baseTemp * 10).rounded() / 10,
            dominantCondition: dominant,
            rainyDays: (seed % 10) + 3, sunnyDays: (seed % 8) + 5
        )
    }
    static func dayWeather(year: Int, month: Int, day: Int) -> HistoricalDayWeather {
        let seed = year * 366 + month * 31 + day
        let condition = WeatherCondition.allCases[seed % WeatherCondition.allCases.count]
        let temp = 10.0 + Double(seed % 20) + Double(month) * 1.1
        return HistoricalDayWeather(
            year: year, month: month, day: day, condition: condition,
            temperatureCelsius: (temp * 10).rounded() / 10,
            rainProbabilityPercent: Double((seed * 17) % 100)
        )
    }
}

// MARK: - Store

@MainActor
@Observable
final class WayBackStore {
    var isPresented = false
    var referenceMonth: Int
    var referenceDay: Int?
    
    /// ScrollView の contentOffset.y（PreferenceKey から更新）
    var rawScrollOffset: CGFloat = 0
    
    let cardScrollHeight: CGFloat = 160
    let minYear = 2000
    var maxYear: Int { Calendar.current.component(.year, from: Date()) - 1 }
    let visibleCardCount = 7
    
    private let apiClient = WeatherAPIClient()
    var dayWeatherCache: [Int: HistoricalDayWeather] = [:]
    var monthSummaryCache: [Int: HistoricalMonthSummary] = [:]
    private var fetchingYears: Set<Int> = [] // 重複して通信するのを防ぐ
    
    // MARK: 方向定義
    // ┌──────────────────────────────────────────────────────────────────┐
    // │  open() で ScrollView を下端（最新年）にジャンプしてスタート    │
    // │  下スクロール → offset 減少 → 古い年が後ろから現れる          │
    // │  上スクロール → offset 増加 → 最新年（手前）に戻る            │
    // │  rawScrollOffset = totalScrollHeight のとき index=0（最新年）   │
    // └──────────────────────────────────────────────────────────────────┘
    
    var totalScrollHeight: CGFloat {
        CGFloat(maxYear - minYear + 1) * cardScrollHeight
    }
    
    /// offset → 「何年前か」の連続値。
    /// 下端（rawScrollOffset 大）= index 小（最新）、上端（rawScrollOffset 小）= index 大（古い）
    var continuousYearIndex: CGFloat {
        let inverted = max(0, totalScrollHeight - rawScrollOffset)
        let raw = inverted / cardScrollHeight
        return max(0, min(CGFloat(maxYear - minYear), raw))
    }
    
    /// 現在の最前面の年
    var frontYear: Int {
        maxYear - Int(continuousYearIndex.rounded())
    }
    
    /// カード間補間率（0.0〜1.0）
    var blendFraction: CGFloat {
        let floored = continuousYearIndex.rounded(.towardZero)
        return continuousYearIndex - floored
    }
    
    /// slot=0 が最前面（frontYear）、奥ほど古い年
    var cardYears: [Int] {
        let base = maxYear - Int(continuousYearIndex.rounded(.towardZero))
        return (0..<visibleCardCount).compactMap { i in
            let y = base - i
            return y >= minYear ? y : nil
        }
    }
    
    init() {
        let now = Date(); let cal = Calendar.current
        referenceMonth = cal.component(.month, from: now)
        referenceDay   = cal.component(.day,   from: now)
    }
    
    func open(referenceDate: Date? = nil) {
        if let date = referenceDate {
            let cal = Calendar.current
            referenceMonth = cal.component(.month, from: date)
            referenceDay   = cal.component(.day,   from: date)
        }
        // 下端（最新年が最前面）からスタート
        rawScrollOffset = totalScrollHeight
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { isPresented = true }
    }
    
    func close() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { isPresented = false }
    }
    
    func selectYear(_ year: Int) {
        // maxYear から何年前か → totalScrollHeight から引く
        let index = CGFloat(maxYear - year)
        let target = totalScrollHeight - index * cardScrollHeight
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            rawScrollOffset = max(0, target)
        }
    }
    
    func monthSummary(for year: Int) -> HistoricalMonthSummary {
        // キャッシュがあればAPIデータを使う
        if let cached = monthSummaryCache[year] { return cached }
        // なければ裏でAPIを呼びつつ、一旦モックを表示しておく
        fetchPastDataIfNeeded(for: year)
        return HistoricalDataStub.monthSummary(year: year, month: referenceMonth)
    }
    
    func dayWeather(for year: Int) -> HistoricalDayWeather? {
        guard let day = referenceDay else { return nil }
        if let cached = dayWeatherCache[year] { return cached }
        fetchPastDataIfNeeded(for: year)
        return HistoricalDataStub.dayWeather(year: year, month: referenceMonth, day: day)
    }
    private func fetchPastDataIfNeeded(for year: Int) {
        guard let day = referenceDay, !fetchingYears.contains(year) else { return }
        
        fetchingYears.insert(year) // 通信中フラグを立てる
        
        Task {
            do {
                let response = try await apiClient.fetchPastWeather(year: year, month: referenceMonth, day: day)
                let hist = response.historicalData
                
                // let condition = WeatherCondition(rawValue: hist.dominantCondition.lowercased()) ?? .sunny
                let condition = WeatherCondition.from(rainProbability: hist.actualRainProbability)
                
                // 本物のデータを保存（保存された瞬間に画面がパッと切り替わります）
                self.dayWeatherCache[year] = HistoricalDayWeather(
                    year: hist.year, month: hist.month, day: hist.day,
                    condition: condition,
                    temperatureCelsius: hist.actualTemp,
                    rainProbabilityPercent: hist.actualRainProbability
                )
                
                self.monthSummaryCache[year] = HistoricalMonthSummary(
                    year: hist.year, month: hist.month,
                    avgTemperatureCelsius: hist.actualTemp,
                    dominantCondition: condition,
                    rainyDays: Int(hist.actualRainProbability / 10),
                    sunnyDays: 10
                )
            } catch {
                print("WayBack API通信エラー (年: \(year)): \(error)")
            }
            self.fetchingYears.remove(year)
        }
    }
}

// MARK: - PreferenceKey

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
