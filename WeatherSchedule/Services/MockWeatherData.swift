import Foundation

// MARK: - モックデータ生成器
//
// DebugSettings.isMockModeEnabled == true のとき、
// WeatherAPIClient の代わりにこのクラスが使われる。
// シード値を日付から生成するため、同じ日付は常に同じ値を返す（再現性あり）。

enum MockWeatherData {

    // MARK: 未来予報モック

    static func forecast(year: Int, month: Int, day: Int) -> ForecastResponse {
        let seed = year * 10000 + month * 100 + day
        let rain  = Double((seed * 37 + 13) % 100)
        let temp  = 10.0 + Double((seed * 7 + 5) % 25)
        let humid = 40.0 + Double((seed * 11 + 3) % 45)
        let score = Int((seed * 3) % 5) + 1

        let advicePool = [
            "気温が安定しており、屋外イベントに適しています。",
            "午後から雨の可能性があります。折りたたみ傘をお持ちください。",
            "湿度が高めです。熱中症対策をしっかりと。",
            "晴れ間が続く見込みです。日焼け止めをお忘れなく。",
            "風が強くなる予報です。テントや看板の固定を確認してください。",
            "過ごしやすい気候が続きます。ピクニックにぴったりの一日です。",
        ]
        let advice = advicePool[seed % advicePool.count]

        return ForecastResponse(
            requestDate: String(format: "%04d-%02d-%02d", year, month, day),
            aiPrediction: AIPrediction(
                rainProbabilityPercent: rain,
                referencePastAverageTemp: (temp * 10).rounded() / 10,
                referencePastAverageHumidity: (humid * 10).rounded() / 10
            ),
            evaluation: Evaluation(eventScore: score, advice: advice)
        )
    }

    // MARK: 過去データモック

    static func pastWeather(year: Int, month: Int, day: Int) -> PastWeatherResponse {
        let seed = year * 10000 + month * 100 + day
        let rain  = Double((seed * 41 + 7) % 100)
        let temp  = 8.0  + Double((seed * 13 + 11) % 28)
        let humid = 35.0 + Double((seed * 17 + 9)  % 50)

        return PastWeatherResponse(
            historicalData: HistoricalWeatherData(
                year: year, month: month, day: day,
                actualRainProbability: rain,
                actualTemp: (temp * 10).rounded() / 10,
                actualHumidity: (humid * 10).rounded() / 10
            )
        )
    }
}

// MARK: - モック対応 WeatherAPIClient 拡張

extension WeatherAPIClient {

    /// デバッグフラグが立っていれば実通信をせずモックを返す。
    func fetchForecastWithMockSupport(year: Int, month: Int, day: Int) async throws -> ForecastResponse {
        if DebugSettings.isMockModeEnabled {
            // 実際の遅延っぽさを演出（省略可）
            try await Task.sleep(nanoseconds: 120_000_000) // 0.12 s
            return MockWeatherData.forecast(year: year, month: month, day: day)
        }
        return try await fetchForecast(year: year, month: month, day: day)
    }

    func fetchPastWeatherWithMockSupport(year: Int, month: Int, day: Int) async throws -> PastWeatherResponse {
        if DebugSettings.isMockModeEnabled {
            try await Task.sleep(nanoseconds: 120_000_000)
            return MockWeatherData.pastWeather(year: year, month: month, day: day)
        }
        return try await fetchPastWeather(year: year, month: month, day: day)
    }
}
