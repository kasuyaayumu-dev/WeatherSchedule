import Foundation

/// 予報データのローカル永続化（オフライン対応の土台）。
/// Documents 配下に JSON 保存し、保存範囲は CacheSettings で制限できる。
@MainActor
final class ForecastCache {
    private(set) var entries: [String: ForecastResponse] = [:]
    
    private let fileURL: URL
    private let formatter: DateFormatter
    private let calendar = Calendar(identifier: .gregorian)
    
    init(filename: String = "forecasts.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appending(path: filename)
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        self.formatter = formatter
        
        load()
    }
    
    /// 保存済みデータが存在するか（起動フローの分岐に使用）。
    var hasSavedData: Bool { !entries.isEmpty }
    
    func key(for date: Date) -> String { formatter.string(from: date) }
    
    func forecast(for date: Date) -> ForecastResponse? { entries[key(for: date)] }
    
    /// 起動時に CalendarStore のメモリキャッシュへ展開するための変換。
    func entriesByDate() -> [Date: ForecastResponse] {
        var result: [Date: ForecastResponse] = [:]
        for (key, value) in entries {
            if let date = formatter.date(from: key) {
                result[calendar.startOfDay(for: date)] = value
            }
        }
        return result
    }
    
    func store(_ forecast: ForecastResponse, for date: Date) {
        entries[key(for: date)] = forecast
        save()
    }
    
    func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([String: ForecastResponse].self, from: data)
        else { return }
        entries = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
    
    /// 設定値に応じて保存範囲外のデータを削除する（設定画面連動の土台）。
    func prune(pastYears: Int = CacheSettings.pastYears,
               futureMonths: Int = CacheSettings.futureMonths,
               reference: Date = Date()) {
        guard
            let lower = calendar.date(byAdding: .year, value: -pastYears, to: reference),
            let upper = calendar.date(byAdding: .month, value: futureMonths, to: reference)
        else { return }
        
        let lowerDay = calendar.startOfDay(for: lower)
        entries = entries.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= lowerDay && date <= upper
        }
        save()
    }
}
