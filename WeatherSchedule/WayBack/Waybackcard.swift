import SwiftUI

// MARK: - Way Back カード（没入感重視・情報集約版）

struct WayBackCard: View {
    var year: Int
    var month: Int
    var day: Int?
    var isFront: Bool
    var depthIndex: Int
    
    private var summary: HistoricalMonthSummary {
        HistoricalDataStub.monthSummary(year: year, month: month)
    }
    private var dayWeather: HistoricalDayWeather? {
        guard let day else { return nil }
        return HistoricalDataStub.dayWeather(year: year, month: month, day: day)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // ── 背景 ──────────────────────────────────
            cardBackground
            
            if isFront {
                frontContent
            } else {
                depthContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(
            color: summary.dominantCondition.tint.opacity(isFront ? 0.30 : 0.08),
            radius: isFront ? 32 : 10,
            y: isFront ? 16 : 4
        )
    }
    
    // MARK: - 背景
    
    private var cardBackground: some View {
        ZStack {
            // ダーク寄りのガラス感
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // 天気カラーのグラデーション（手前ほど鮮やか）
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            summary.dominantCondition.tint.opacity(isFront ? 0.28 : 0.10),
                            Color.black.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 上端の光沢ライン
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(isFront ? 0.45 : 0.18), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - 最前面カード（フル情報）
    
    private var frontContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── 上段: 年 + 天気アイコン ────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // 年を大きく・主役に
                    Text("\(year)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: summary.dominantCondition.tint.opacity(0.6), radius: 16)
                    
                    // 月日をサブに
                    if let label = dateLabel {
                        Text(label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                Spacer()
                // 天気アイコンを右上に大きく
                Image(systemName: summary.dominantCondition.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 52))
                    .shadow(color: summary.dominantCondition.tint.opacity(0.5), radius: 20)
                    .padding(.top, 6)
            }
            .padding(.top, 28)
            .padding(.horizontal, 24)
            
            Spacer(minLength: 16)
            
            // ── 下段: 3メトリクス ──────────────────────
            HStack(spacing: 10) {
                metric(
                    value: String(format: "%.1f°", summary.avgTemperatureCelsius),
                    label: "平均気温",
                    symbol: "thermometer.medium",
                    tint: .orange
                )
                metric(
                    value: "\(summary.sunnyDays)日",
                    label: "晴れ",
                    symbol: "sun.max.fill",
                    tint: .yellow
                )
                metric(
                    value: "\(summary.rainyDays)日",
                    label: "雨",
                    symbol: "cloud.rain.fill",
                    tint: .blue
                )
            }
            .padding(.horizontal, 16)
            
            // ── 日付指定データ（あれば）────────────────
            if let dw = dayWeather {
                dayRow(dw)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }
            
            Spacer(minLength: 22)
        }
    }
    
    // MARK: - 奥のカード（年だけ大きく・ミニマル）
    
    private var depthContent: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(year)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Image(systemName: summary.dominantCondition.symbol)
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .opacity(0.40)
        }
        .padding(.top, 20)
        .padding(.horizontal, 22)
    }
    
    // MARK: - サブビュー
    
    private func metric(value: String, label: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
            Text(value)
                .font(.callout.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func dayRow(_ dw: HistoricalDayWeather) -> some View {
        HStack(spacing: 12) {
            Image(systemName: dw.condition.symbol)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("この日の記録")
                    .font(.caption2).foregroundStyle(.white.opacity(0.40))
                Text("\(dw.condition.label)  \(String(format: "%.1f°", dw.temperatureCelsius))  降水 \(Int(dw.rainProbabilityPercent))%")
                    .font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.80))
            }
            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var dateLabel: String? {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day ?? 1
        guard let date = Calendar.current.date(from: comps) else { return nil }
        if let day {
            _ = day
            return date.formatted(.dateTime.month(.wide).day())
        }
        return date.formatted(.dateTime.month(.wide))
    }
}
