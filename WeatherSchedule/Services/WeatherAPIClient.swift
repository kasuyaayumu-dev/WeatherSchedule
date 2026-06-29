import Foundation

struct WeatherAPIClient {
    // シミュレーターは Mac の localhost を共有するため 127.0.0.1 で接続できる。
    // 実機で動かす場合は Mac のローカル IP（例: "192.168.1.10"）に変更する。
    var host = "127.0.0.1"
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
    func fetchPastWeather(year: Int, month: Int, day: Int) async throws -> PastWeatherResponse {
        guard let url = URL(string: "http://\(host):\(port)/forecast/past/\(year)/\(month)/\(day)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(PastWeatherResponse.self, from: data)
    }
}
