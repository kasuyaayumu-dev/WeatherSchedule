import SwiftUI

// MARK: - カード1枚

/// Way Back モードの1年分カード。
struct WayBackCard: View {
  var year: Int
  var month: Int
  var day: Int?
  var isFront: Bool
  var depthIndex: Int   // 0 = 最前面

  private var summary: HistoricalMonthSummary {
    HistoricalDataStub.monthSummary(year: year, month: month)
  }
  private var dayWeather: HistoricalDayWeather? {
    guard let day else { return nil }
    return HistoricalDataStub.dayWeather(year: year, month: month, day: day)
  }
  private var monthName: String {
    DateFormatter().monthSymbols[month - 1]
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      // 背景
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
              LinearGradient(
                colors: [
                  summary.dominantCondition.tint.opacity(isFront ? 0.22 : 0.10),
                  Color(.systemBackground).opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        }
        .overlay {
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(
              LinearGradient(
                colors: [.white.opacity(0.55), .white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        }

      if isFront {
        frontContent
      } else {
        backContent
      }
    }
    .shadow(
      color: .black.opacity(isFront ? 0.22 : 0.10),
      radius: isFront ? 28 : 12,
      y: isFront ? 14 : 6
    )
  }

  // MARK: - 最前面カード（詳細）

  private var frontContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      // ヘッダー
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text("\(year)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
          Text("\(monthName)\(day.map { " \($0)日" } ?? "")")
            .font(.title3.weight(.medium))
            .foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: summary.dominantCondition.symbol)
          .symbolRenderingMode(.multicolor)
          .font(.system(size: 44))
          .shadow(color: summary.dominantCondition.tint.opacity(0.4), radius: 12)
      }
      .padding(.top, 28)
      .padding(.horizontal, 24)

      Divider()
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)

      // メトリクス行
      HStack(spacing: 0) {
        metricItem(
          title: "平均気温",
          value: String(format: "%.1f°", summary.avgTemperatureCelsius),
          symbol: "thermometer.medium",
          tint: .orange
        )
        metricDivider
        metricItem(
          title: "晴れの日",
          value: "\(summary.sunnyDays)日",
          symbol: "sun.max.fill",
          tint: .yellow
        )
        metricDivider
        metricItem(
          title: "雨の日",
          value: "\(summary.rainyDays)日",
          symbol: "cloud.rain.fill",
          tint: .blue
        )
      }
      .padding(.horizontal, 12)

      // 日付指定データ（referenceDay あり）
      if let dw = dayWeather {
        Divider()
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 12)

        dayDetailRow(dw)
          .padding(.horizontal, 24)
      }

      Spacer(minLength: 20)

      // フッター
      HStack {
        Image(systemName: "sparkles")
          .foregroundStyle(.secondary)
          .font(.caption)
        Text("過去データ（モック）")
          .font(.caption)
          .foregroundStyle(.tertiary)
        Spacer()
        Text("Way Back")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.quaternary)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 22)
    }
  }

  // MARK: - 奥のカード（省略表示）

  private var backContent: some View {
    HStack(alignment: .firstTextBaseline) {
      Text("\(year)")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(.primary.opacity(0.6))
      Spacer()
      Image(systemName: summary.dominantCondition.symbol)
        .symbolRenderingMode(.multicolor)
        .font(.title)
        .opacity(0.5)
    }
    .padding(.top, 22)
    .padding(.horizontal, 22)
  }

  // MARK: - サブコンポーネント

  private func metricItem(title: String, value: String, symbol: String, tint: Color) -> some View {
    VStack(spacing: 6) {
      Image(systemName: symbol)
        .symbolRenderingMode(.multicolor)
        .font(.title3)
      Text(value)
        .font(.callout.weight(.semibold))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
      Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 4)
  }

  private var metricDivider: some View {
    EmptyView()
  }

  private func dayDetailRow(_ dw: HistoricalDayWeather) -> some View {
    HStack(spacing: 14) {
      Image(systemName: dw.condition.symbol)
        .symbolRenderingMode(.multicolor)
        .font(.system(size: 28))

      VStack(alignment: .leading, spacing: 2) {
        Text("この日の記録")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text("\(dw.condition.label)  \(String(format: "%.1f°", dw.temperatureCelsius))  降水 \(String(format: "%.0f%%", dw.rainProbabilityPercent))")
          .font(.subheadline.weight(.semibold))
      }
      Spacer()
    }
    .padding(14)
    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}
