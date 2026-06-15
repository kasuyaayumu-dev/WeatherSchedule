import Foundation

// MARK: - Response Models

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
