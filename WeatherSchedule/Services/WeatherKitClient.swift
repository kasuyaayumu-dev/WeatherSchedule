// WeatherKit は Apple Developer Program のケイパビリティが必要なため
// 現在はコメントアウト中。親アカウントでの受け取り後に有効化予定。
//
// import Foundation
// import WeatherKit
// import CoreLocation
//
// @MainActor
// final class WeatherKitClient {
//     static let shared = WeatherKitClient()
//     private let service = WeatherService.shared
//     private var cache: [Date: DayWeatherSummary] = [:]
//     private init() {}
//
//     func prefetch(for location: CLLocation = .tokyo) async {
//         do {
//             let weather = try await service.weather(for: location, including: .daily)
//             let cal = Calendar.current
//             for day in weather.forecast {
//                 let key = cal.startOfDay(for: day.date)
//                 cache[key] = DayWeatherSummary(
//                     date: key,
//                     condition: WeatherCondition.from(
//                         rainProbability: day.precipitationChance * 100,
//                         temperature: day.highTemperature.converted(to: .celsius).value
//                     ),
//                     highTemp: day.highTemperature.converted(to: .celsius).value,
//                     lowTemp:  day.lowTemperature.converted(to: .celsius).value,
//                     rainProbabilityPercent: day.precipitationChance * 100,
//                     symbolName: day.symbolName
//                 )
//             }
//         } catch {
//             print("WeatherKit prefetch error: \(error)")
//         }
//     }
//
//     func summary(for date: Date) -> DayWeatherSummary? {
//         cache[Calendar.current.startOfDay(for: date)]
//     }
//
//     static func isWithin10Days(_ date: Date) -> Bool {
//         let cal = Calendar.current
//         guard let limit = cal.date(byAdding: .day, value: 10, to: cal.startOfDay(for: Date())) else { return false }
//         return cal.startOfDay(for: date) < limit
//     }
// }
//
// struct DayWeatherSummary {
//     var date: Date
//     var condition: WeatherCondition
//     var highTemp: Double
//     var lowTemp: Double
//     var rainProbabilityPercent: Double
//     var symbolName: String
// }
//
// extension CLLocation {
//     static let tokyo = CLLocation(latitude: 35.6812, longitude: 139.7671)
// }
