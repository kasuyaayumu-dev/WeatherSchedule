import Foundation

// MARK: - 未来予報レスポンス（既存）

struct ForecastResponse: Codable {
    var requestDate: String
    var aiPrediction: AIPrediction
    var evaluation: Evaluation

    enum CodingKeys: String, CodingKey {
        case requestDate = "request_date"
        case aiPrediction = "ai_prediction"
        case evaluation
    }
}

struct AIPrediction: Codable {
    var rainProbabilityPercent: Double
    var referencePastAverageTemp: Double
    var referencePastAverageHumidity: Double

    enum CodingKeys: String, CodingKey {
        case rainProbabilityPercent = "rain_probability_percent"
        case referencePastAverageTemp = "reference_past_average_temp"
        case referencePastAverageHumidity = "reference_past_average_humidity"
    }
}

struct Evaluation: Codable {
    var eventScore: Int
    var advice: String

    enum CodingKeys: String, CodingKey {
        case eventScore = "event_score"
        case advice
    }
}

// MARK: - 過去データレスポンス（Way Back 用）
// FastAPI エンドポイント: GET /forecast/past/{year}/{month}/{day}

struct PastWeatherResponse: Codable {
    var historicalData: HistoricalWeatherData

    enum CodingKeys: String, CodingKey {
        case historicalData = "historical_data"
    }
}

struct HistoricalWeatherData: Codable {
    var year: Int
    var month: Int
    var day: Int
    /// 実際の降水確率（%）
    var actualRainProbability: Double
    /// 実際の気温（℃）
    var actualTemp: Double
    /// 実際の湿度（%）
    var actualHumidity: Double

    enum CodingKeys: String, CodingKey {
        case year
        case month
        case day
        case actualRainProbability = "actual_rain_probability"
        case actualTemp            = "actual_temp"
        case actualHumidity        = "actual_humidity"
    }
}
