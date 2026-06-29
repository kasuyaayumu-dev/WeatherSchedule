import Foundation

/// キャッシュ保存範囲の設定。設定画面(@AppStorage)と AppDataManager で同じキーを共有する。
/// 将来、歯車アイコンの設定画面から「過去◯年・未来◯ヶ月」を調整できるようにするための土台。
enum CacheSettings {
    static let pastYearsKey = "cache.pastYears"
    static let futureMonthsKey = "cache.futureMonths"
    
    static let defaultPastYears = 1
    static let defaultFutureMonths = 24
    
    /// View 以外（AppDataManager など）からは UserDefaults を直接参照する。
    static var pastYears: Int {
        UserDefaults.standard.object(forKey: pastYearsKey) as? Int ?? defaultPastYears
    }
    
    static var futureMonths: Int {
        UserDefaults.standard.object(forKey: futureMonthsKey) as? Int ?? defaultFutureMonths
    }
}
