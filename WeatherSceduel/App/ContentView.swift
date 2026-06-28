import SwiftUI

@main struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

struct ContentView: View {
  private let client = WeatherAPIClient()
  @State private var resultText = "未取得"

  var body: some View {
    VStack(spacing: 20) {
      Button("API通信テスト") {
        Task { await runTest() }
      }

      Text(resultText)
    }
    .padding()
  }

  private func runTest() async {
    resultText = "通信中…"
    do {
      let forecast = try await client.fetchForecast(year: 2027, month: 8, day: 15)
      resultText = """
      日付: \(forecast.requestDate)
      降水確率: \(forecast.aiPrediction.rainProbabilityPercent)%
      平均気温: \(forecast.aiPrediction.referencePastAverageTemp)
      平均湿度: \(forecast.aiPrediction.referencePastAverageHumidity)
      スコア: \(forecast.evaluation.eventScore)
      アドバイス: \(forecast.evaluation.advice)
      """
    } catch {
      resultText = "エラー: \(error.localizedDescription)"
    }
  }
}
