import Foundation
import Observation
import SwiftUI

/// 詳細ビューの通信状態。
enum ForecastState {
    case loading
    case loaded(ForecastResponse)
    case failed
}

/// カレンダー画面の状態を保持するモデル層。
/// 暦に正確な月グリッドの生成・選択管理・API 通信を担い、View からロジックを切り離す。
@MainActor
@Observable
final class CalendarStore {
    /// 過去・未来に生成する月数。
    static let pastMonths = 12
    static let futureMonths = 24
    
    private(set) var months: [CalendarMonth]
    var selectedDate: Date?
    
    /// 選択中の日付に対する API 通信状態。
    private(set) var forecastState: ForecastState?
    
    /// 日付ごとに取得済みの予報（アイコン表示用）。キーは startOfDay。
    private(set) var forecasts: [Date: ForecastResponse] = [:]
    
    /// 現在スクロールで一番上に見えている月（ScrollPosition と連動）。
    var visibleMonthID: Date?
    
    private let calendar: Calendar
    private let client = WeatherAPIClient()
    private let cache: ForecastCache
    private let network: NetworkMonitor
    private var loadTask: Task<Void, Never>?
    private var inFlightDays: Set<Date> = []
    
    init(cache: ForecastCache, network: NetworkMonitor) {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        self.calendar = calendar
        self.cache = cache
        self.network = network
        self.months = CalendarStore.buildMonths(calendar: calendar)
        self.forecasts = cache.entriesByDate() // 保存済みデータでアイコンを初期表示
    }
    
    /// 保存済みキャッシュをメモリへ再展開する（起動完了時に呼ぶ）。
    func reloadFromCache() {
        forecasts = cache.entriesByDate()
    }
    
    /// 今月の初日（スクロール起点／比較用）。
    var todayMonthID: Date {
        CalendarStore.startOfMonth(for: Date(), calendar: calendar)
    }
    
    func scrollToTodayMonth() {
        let targetMonthID = todayMonthID
        visibleMonthID = nil
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                self.visibleMonthID = targetMonthID
            }
        }
        prefetchMonth(id: targetMonthID)
    }
    
    /// 上部ヘッダーに出す「見えている月 + 年」。
    var navigationTitle: String {
        (visibleMonthID ?? Date()).formatted(.dateTime.month(.wide).year())
    }
    
    /// 選択中の日付に対応する詳細データ。
    var selectedDay: CalendarDay? {
        selectedDate.map { CalendarDay(date: $0) }
    }
    
    func isSelected(_ day: CalendarDay) -> Bool {
        guard let selectedDate else { return false }
        return calendar.isDate(selectedDate, inSameDayAs: day.date)
    }
    
    /// 同じ日付を再タップすると選択解除。選択時は API 通信を開始する。
    func toggleSelection(_ day: CalendarDay) {
        if isSelected(day) {
            clearSelection()
        } else {
            selectedDate = day.date
            loadForecast(for: day.date)
        }
    }
    
    func clearSelection() {
        loadTask?.cancel()
        loadTask = nil
        selectedDate = nil
        forecastState = nil
    }
    
    /// 選択中の日付で通信をやり直す（エラー時の再試行用）。
    func retry() {
        guard let selectedDate else { return }
        loadForecast(for: selectedDate)
    }
    
    private func loadForecast(for date: Date) {
        loadTask?.cancel()
        let key = calendar.startOfDay(for: date)
        
        // オフラインファースト：キャッシュがあればまず即表示。
        if let cached = forecasts[key] {
            forecastState = .loaded(cached)
            return
        }
        
        // 未取得かつオフラインなら通信せず失敗表示。
        guard network.isOnline else {
            forecastState = .failed
            return
        }
        
        forecastState = .loading
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else {
            forecastState = .failed
            return
        }
        
        loadTask = Task { [client, cache] in
            do {
                let result = try await client.fetchForecast(year: year, month: month, day: day)
                guard !Task.isCancelled else { return }
                forecasts[key] = result          // アイコンへ反映
                cache.store(result, for: key)     // ローカルへ保存
                withAnimation(.smooth) { forecastState = .loaded(result) }
            } catch {
                guard !Task.isCancelled else { return }
                withAnimation(.smooth) { forecastState = .failed }
            }
        }
    }
    
    // MARK: - アイコン用の予報プリフェッチ
    
    /// 取得済みなら API の降水確率から判定した天気を返す（未取得は nil）。
    func forecast(for date: Date) -> ForecastResponse? {
        forecasts[calendar.startOfDay(for: date)]
    }
    
    func condition(for date: Date) -> WeatherCondition? {
        guard let forecast = forecast(for: date) else { return nil }
        return WeatherCondition.from(
            rainProbability: forecast.aiPrediction.rainProbabilityPercent,
            temperature: forecast.aiPrediction.referencePastAverageTemp
        )
    }
    
    /// 指定 ID の月に含まれる（今日以降の）日をまとめて先読みする。
    func prefetchMonth(id: Date?) {
        guard let id, let month = months.first(where: { $0.id == id }) else { return }
        for day in month.days {
            prefetchDay(day.date)
        }
    }
    
    private func prefetchDay(_ date: Date) {
        let key = calendar.startOfDay(for: date)
        // 取得済み・取得中はスキップ（過去日も含めて最初から正しいアイコンにする）。
        guard forecasts[key] == nil, !inFlightDays.contains(key) else { return }
        // オフライン時は先読みしない（キャッシュのみで表示）。
        guard network.isOnline else { return }
        
        let parts = calendar.dateComponents([.year, .month, .day], from: key)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return }
        
        inFlightDays.insert(key)
        Task { [client, cache] in
            defer { inFlightDays.remove(key) }
            do {
                let result = try await client.fetchForecast(year: year, month: month, day: day)
                forecasts[key] = result
                cache.store(result, for: key) // ローカルへ保存
            } catch {
                // 失敗時はフォールバックのアイコンのまま。
            }
        }
    }
    
    // MARK: - 月グリッドの生成
    
    private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
    
    private static func buildMonths(calendar: Calendar) -> [CalendarMonth] {
        let base = startOfMonth(for: Date(), calendar: calendar)
        
        return (-pastMonths...futureMonths).compactMap { offset in
            guard
                let first = calendar.date(byAdding: .month, value: offset, to: base),
                let dayRange = calendar.range(of: .day, in: .month, for: first)
            else { return nil }
            
            // 1 日の曜日から、先頭に必要な空白セル数を求める。
            let weekday = calendar.component(.weekday, from: first)
            let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7
            
            let days: [CalendarDay] = dayRange.compactMap { dayNumber in
                guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: first) else { return nil }
                return CalendarDay(date: calendar.startOfDay(for: date))
            }
            
            return CalendarMonth(firstDay: first, leadingBlanks: leadingBlanks, days: days)
        }
    }
}
