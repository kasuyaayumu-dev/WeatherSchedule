import SwiftUI

// MARK: - DayDetailView
//
// 変更点（v2）:
//   • loadedContent に AIInsightCard を追加（Apple Intelligence 風）
//   • onMinimize コールバックを追加（ミニプレーヤーへ縮小）
//   • SettingsView が miniPlayer を無効にしている場合は縮小せず完全クローズ

struct DayDetailView: View {
    var date: Date
    var state: ForecastState?
    var onClose: () -> Void
    var onRetry: () -> Void
    var onWayBack: () -> Void
    /// ミニプレーヤーが有効な場合に呼ばれる。nil の場合は縮小ボタン非表示。
    var onMinimize: (() -> Void)?
    
    @State private var showEventEditor = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    actionButtons
                    content
                    AIButton
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("日付詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ── 左：縮小ボタン（ミニプレーヤー有効時のみ） ──
                if let onMinimize {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onMinimize()
                        } label: {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("縮小")
                    }
                }
                
                // ── 右：完了ボタン ──
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了", action: onClose)
                }
            }
        }
        .interactiveDismissDisabled(false) // スワイプで閉じを許可（ミニプレーヤーはカレンダー側が制御）
        .sheet(isPresented: $showEventEditor) {
            CalendarEventEditView(date: date)
        }
    }
    
    // MARK: - ヘッダー
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.title2.weight(.semibold))
            Label("AI予測", systemImage: "sparkles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - アクションボタン
    
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
    
    @State private var animateGradient = false
    
    private var AIButton: some View {
            Button {
                // TODO: AIモードのアクションを実装
                print("AI Mode tapped in DayDetailView")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .symbolEffect(.pulse)
                    Text("AIモード")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.4, blue: 0.9), // ピンク
                                    Color(red: 0.4,  green: 0.6, blue: 1.0), // ブルー
                                    Color(red: 0.3,  green: 0.9, blue: 0.8)  // ミント
                                ],
                                // 🌟 位置関係を反転させず、外側から内側へ近づけたり離したりする
                                startPoint: animateGradient ? UnitPoint(x: 0.1, y: 0.1) : UnitPoint(x: -0.3, y: -0.3),
                                endPoint: animateGradient ? UnitPoint(x: 0.9, y: 0.9) : UnitPoint(x: 1.3, y: 1.3)
                            )
                        )
                        .shadow(color: Color(red: 0.7, green: 0.4, blue: 1.0).opacity(0.5), radius: 10, y: 4)
                )
            }
            .buttonStyle(.plain)
            .onAppear {
                // 🌟 3.5秒かけてゆっくりと「近づいて離れて」を無限ループ
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
        }
    
    // MARK: - コンテンツ（通信状態に応じて切り替え）
    
    @ViewBuilder private var content: some View {
        switch state {
        case .loading, .none:
            loadingView
            
        case .loaded(let forecast):
            loadedContent(forecast)
            
        case .failed:
            failureContent
        }
    }
    
    // MARK: - ローディング
    
    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("AIに問い合わせ中…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 読み込み済みコンテンツ
    
    private func loadedContent(_ forecast: ForecastResponse) -> some View {
        let condition = WeatherCondition.from(
            rainProbability: forecast.aiPrediction.rainProbabilityPercent,
            temperature: forecast.aiPrediction.referencePastAverageTemp
        )
        
        return VStack(alignment: .leading, spacing: 14) {
            // ── 天気ヘッダー ──────────────────────────────
            HStack(spacing: 14) {
                Image(systemName: condition.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 40))
                Text(condition.label)
                    .font(.title3.weight(.semibold))
                Spacer()
            }
            
            // ── メトリクスカード ──────────────────────────
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
            
            //            // ── AI アドバイス（旧） ───────────────────────
            //            HStack(alignment: .top, spacing: 10) {
            //                Image(systemName: "sparkles")
            //                    .foregroundStyle(.tint)
            //                Text(forecast.evaluation.advice)
            //                    .font(.subheadline)
            //                    .fixedSize(horizontal: false, vertical: true)
            //            }
            //            .frame(maxWidth: .infinity, alignment: .leading)
            //            .padding(12)
            //            .background(Color(.secondarySystemGroupedBackground),
            //                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // ── AI インサイトカード（新規）────────────────
            AIInsightCard(date: date, forecast: forecast)
        }
        .padding(16)
        .background(Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - メトリクスカード
    
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
        .background(tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - エラー
    
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
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
