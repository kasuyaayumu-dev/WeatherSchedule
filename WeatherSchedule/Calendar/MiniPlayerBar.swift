import SwiftUI

// MARK: - ミニプレーヤーバー
//
// モーダルを下スワイプで閉じた後、画面下部に残る情報バー。
// 降水確率・平均気温を一目で確認でき、再タップでモーダルが再展開する。

struct MiniPlayerBar: View {
    var forecast: ForecastResponse
    var date: Date
    var onExpand: () -> Void
    var onDismiss: () -> Void
    var onTodayTap: () -> Void
    var onAIChatTap: () -> Void

    // ミニプレーヤーが画面外から滑り込む
    @State private var appeared = false
    
    @State private var dragOffset: CGFloat = 0

    private let condition: WeatherCondition

    init(
        forecast: ForecastResponse,
        date: Date,
        onExpand: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onTodayTap: @escaping () -> Void,
        onAIChatTap: @escaping () -> Void
    ) {
        self.forecast    = forecast
        self.date        = date
        self.onExpand    = onExpand
        self.onDismiss   = onDismiss
        self.onTodayTap  = onTodayTap
        self.onAIChatTap = onAIChatTap
        self.condition   = WeatherCondition.from(
            rainProbability: forecast.aiPrediction.rainProbabilityPercent,
            temperature: forecast.aiPrediction.referencePastAverageTemp
        )
    }

    var body: some View {
            VStack(spacing: 0) {
                // ── ミニプレーヤー本体 ──────────────────────────
                // 🌟修正: ButtonをやめてHStackに直接onTapGestureを付ける（誤爆防止）
                HStack(spacing: 12) {
                    // 天気アイコン
                    Image(systemName: condition.symbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 22))
                        .frame(width: 34, height: 34)

                    // 日付
                    VStack(alignment: .leading, spacing: 1) {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(condition.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    // 降水確率
                    metricPill(
                        value: String(format: "%.0f%%", forecast.aiPrediction.rainProbabilityPercent),
                        symbol: "drop.fill",
                        tint: .blue
                    )

                    // 気温
                    metricPill(
                        value: String(format: "%.0f°", forecast.aiPrediction.referencePastAverageTemp),
                        symbol: "thermometer.medium",
                        tint: .orange
                    )

                    // 閉じるボタン
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle()) // 全体に判定を持たせる
                .onTapGesture {
                    onExpand() // タップ時のみ展開
                }

                Divider()
                    .padding(.horizontal, 12)

                // ── フローティングバー（Today / AI Chat） ────────
                HStack(spacing: 16) {
                    Button {
                        onTodayTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Today")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        onAIChatTap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.4, blue: 0.9),
                                            Color(red: 0.4,  green: 0.6, blue: 1.0),
                                            Color(red: 0.3,  green: 0.9, blue: 0.8),
                                            Color(red: 0.95, green: 0.4, blue: 0.9)
                                        ],
                                        center: .center
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .shadow(color: Color(red: 0.7, green: 0.4, blue: 1.0).opacity(0.5), radius: 10, y: 4)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("AIチャット")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
            )
            .offset(y: appeared ? dragOffset : 80)
            .opacity(appeared ? (1.0 - dragOffset / 300.0) : 0)
            // 🌟修正: minimumDistanceを追加し、アニメーションを自然に調整
            .gesture(
                DragGesture(minimumDistance: 15) // 指を15px動かさないとスワイプ開始とみなさない（誤爆防止）
                    .onChanged { value in
                        if value.translation.height > 0 {
                            // ドラッグ中は即座に指に追従
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        // 閉じる判定：一定距離スワイプするか、勢いよくスワイプした時
                        if value.translation.height > 60 || value.predictedEndTranslation.height > 150 {
                            // 抵抗なくスッと下に落ちるアニメーション
                            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 1.0, blendDuration: 0.1)) {
                                dragOffset = UIScreen.main.bounds.height / 2
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onDismiss()
                            }
                        } else {
                            // 閉じる条件に満たなかった場合は、少しバネ感を持たせて戻る
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    appeared = true
                }
            }
        }

    // MARK: - メトリクスピル

    private func metricPill(value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }
}

// MARK: - MiniPlayerState

/// ミニプレーヤーの表示状態をカレンダー画面全体で共有する。
@MainActor
@Observable
final class MiniPlayerState {
    var isVisible: Bool = false
    var forecast: ForecastResponse?
    var date: Date?

    func show(forecast: ForecastResponse, date: Date) {
        self.forecast = forecast
        self.date     = date
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isVisible = true
        }
    }

    func hide() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isVisible = false
        }
    }

    func clear() {
        isVisible = false
        forecast  = nil
        date      = nil
    }
}
