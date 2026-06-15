import Foundation

struct WeatherAPIClient {
  // TODO: MacのローカルIPに置き換えてください（例: "192.168.1.10"）
  var host = "192.168.68.62"
  var port = 8000

  func fetchForecast(year: Int, month: Int, day: Int) async throws -> ForecastResponse {
    guard let url = URL(string: "http://\(host):\(port)/forecast/future/\(year)/\(month)/\(day)") else {
      throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
      throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(ForecastResponse.self, from: data)
  }
}
