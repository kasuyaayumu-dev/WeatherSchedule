import SwiftUI

/// 日付タップ時に表示する標準モーダル用の詳細ビュー。API の通信状態に応じて表示を切り替える。
struct DayDetailView: View {
    var date: Date
    var state: ForecastState?
    var onClose: () -> Void
    var onRetry: () -> Void
    var onWayBack: () -> Void
    
    @State private var showEventEditor = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    actionButtons
                    content
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("日付詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了", action: onClose)
                }
            }
        }
        .sheet(isPresented: $showEventEditor) {
            CalendarEventEditView(date: date)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.title2.weight(.semibold))
            Label("AI予測", systemImage: "sparkles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onWayBack) {
                Label("Way Back", systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            Button {
                showEventEditor = true
            } label: {
                Label("予定を追加", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .labelStyle(.titleAndIcon)
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
            .padding(.vertical, 28)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
        case .loaded(let forecast):
            loadedContent(forecast)
            
        case .failed:
            failureContent
        }
    }
    
    private func loadedContent(_ forecast: ForecastResponse) -> some View {
        let condition = WeatherCondition.from(
            rainProbability: forecast.aiPrediction.rainProbabilityPercent,
            temperature: forecast.aiPrediction.referencePastAverageTemp
        )
        
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
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
