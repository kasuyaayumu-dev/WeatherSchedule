import SwiftUI

/// 日付タップ時に下部へ展開する詳細カード。API の通信状態に応じて表示を切り替える。
struct DayDetailView: View {
  var date: Date
  var state: ForecastState?
  var onClose: () -> Void
  var onRetry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      content
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .strokeBorder(.quaternary, lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 2) {
        Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
          .font(.headline)
        Label("AI予測", systemImage: "sparkles")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button(action: onClose) {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("閉じる")
    }
  }

  @ViewBuilder private var content: some View {
    switch state {
    case .loading, .none:
      HStack(spacing: 10) {
        ProgressView()
        Text("AIに問い合わせ中…")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)

    case .loaded(let forecast):
      loadedContent(forecast)

    case .failed:
      failureContent
    }
  }

  private func loadedContent(_ forecast: ForecastResponse) -> some View {
    let condition = WeatherCondition.from(rainProbability: forecast.aiPrediction.rainProbabilityPercent)

    return VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 14) {
        Image(systemName: condition.symbol)
          .symbolRenderingMode(.multicolor)
          .font(.system(size: 40))
        Text(condition.label)
          .font(.title3.weight(.semibold))
        Spacer()
      }

      HStack(spacing: 10) {
        metricCard(
          title: "降水確率",
          value: String(format: "%.1f%%", forecast.aiPrediction.rainProbabilityPercent),
          symbol: "drop.fill",
          tint: .blue
        )
        metricCard(
          title: "平均気温",
          value: String(format: "%.1f°", forecast.aiPrediction.referencePastAverageTemp),
          symbol: "thermometer.medium",
          tint: .orange
        )
        metricCard(
          title: "平均湿度",
          value: String(format: "%.1f%%", forecast.aiPrediction.referencePastAverageHumidity),
          symbol: "humidity.fill",
          tint: .teal
        )
      }

      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "sparkles")
          .foregroundStyle(.tint)
        Text(forecast.evaluation.advice)
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

      Label("イベントスコア \(forecast.evaluation.eventScore)", systemImage: "star.fill")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
  }

  private func metricCard(title: String, value: String, symbol: String, tint: Color) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Image(systemName: symbol)
        .font(.title3)
        .foregroundStyle(tint)
      Text(value)
        .font(.callout.weight(.semibold))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
      Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private var failureContent: some View {
    VStack(spacing: 10) {
      Image(systemName: "antenna.radiowaves.left.and.right.slash")
        .font(.title)
        .foregroundStyle(.secondary)
      Text("AIに接続できませんでした")
        .font(.subheadline.weight(.semibold))
      Text("ネットワークとサーバーの状態を確認してください。")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button("再試行", systemImage: "arrow.clockwise", action: onRetry)
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .padding(.top, 2)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
  }
}
