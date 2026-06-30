import SwiftUI

/// カレンダーの 1 日分セル。表示モードに応じて天気・データ・予定を描画。
///
/// ### フィルターUI変更点（v2）
/// 旧: 非該当セルを opacity 0.22 で暗くする
/// 新: 該当セルをリング＋グローでハイライト、非該当は彩度を落として背景に引く
struct CalendarCellView: View {
    var day: CalendarDay
    var condition: WeatherCondition
    var forecast: ForecastResponse?
    var events: [ExternalCalendarEvent]
    var displayMode: CalendarDisplayMode
    var isFilteredOut: Bool      // フィルターに一致しない（ハイライト対象外）
    var isSelected: Bool
    var action: () -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(day.date) }
    private var isPast: Bool {
        Calendar.current.startOfDay(for: day.date) < Calendar.current.startOfDay(for: Date())
    }
    private var dayNumber: Int { Calendar.current.component(.day, from: day.date) }

    // フィルターが何も選択されていない（= "すべて"）かどうかは呼び出し元が
    // isFilteredOut=false に統一することで表現する。
    // isFilteredOut=false → ハイライト対象 or フィルター未使用
    // isFilteredOut=true  → フィルター対象外（グレーアウト）

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                // ── 日付番号 ──────────────────────────────────
                Text("\(dayNumber)")
                                    .font(.callout.weight(isToday ? .bold : .regular))
                                    .monospacedDigit()
                                    .foregroundStyle(numberColor)
                                    .frame(width: 30, height: 30)
                                    .background(dateIndicator)

                // ── モードコンテンツ ──────────────────────────
                modeContent
                                    .frame(height: 34)
                                    .saturation(isFilteredOut ? 0.3 : 1.0) // 彩度ダウン
                                    .opacity(isFilteredOut ? 0.8 : 1.0)     // 透明度を下げて薄くする
                                    .opacity(isPast ? 0.55 : 1.0)           // 過去日の処理も維持
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.vertical, 6)
            // ── ハイライトリング（フィルター一致時） ──────────
            .background(highlightBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // フィルター対象外は彩度を下げて背景に沈める（暗くするより自然）
        .animation(.easeInOut(duration: 0.2), value: isFilteredOut)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - ハイライト背景

    @ViewBuilder private var highlightBackground: some View {
        if !isFilteredOut {
            // フィルターが有効（= isFilteredOut が意味を持つ）かどうかは
            // 外部から渡される。isFilteredOut == false でも常にここが呼ばれるが、
            // "フィルター未使用" 状態では両方 false になるのでリングは出ない。
            // → View modifier で制御するため、呼び出し元が
            //   "フィルター未使用" のとき isFilteredOut=false のままにすること。
            EmptyView()
        }
    }

    // MARK: - モードコンテンツ

    @ViewBuilder private var modeContent: some View {
        switch displayMode {
        case .weatherIcon:
            ZStack {
                // グロー（フィルター一致 & 非選択 & 非過去 のときだけ）
                if !isFilteredOut && !isSelected && !isPast {
                    glowRing
                }
                Image(systemName: condition.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 17))
                    .contentTransition(.symbolEffect(.replace))
            }

        case .weatherData:
            ZStack(alignment: .top) {
                if !isFilteredOut && !isSelected && !isPast {
                    glowRing
                        .offset(y: -4)
                }
                VStack(spacing: 2) {
                    Label(rainText, systemImage: "drop.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.blue)
                    Label(temperatureText, systemImage: "thermometer.medium")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.orange)
                }
                .font(.caption2.weight(.semibold))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            }

        case .schedule:
            if let firstEvent = events.first {
                VStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(firstEvent.title)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .padding(.horizontal, 3)
            } else {
                Image(systemName: condition.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 15))
                    .opacity(0.55)
            }
        }
    }

    // MARK: - グロー＋リング

    /// フィルター一致セルに付くハイライトリング。
    /// 条件アイコンのアクセントカラーをそのまま使うことで
    /// "晴れは黄色、雨は青" のように直感的になる。
    @ViewBuilder private var glowRing: some View {
        let accent = condition.accentColor

        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(accent.opacity(0.85), lineWidth: 1.5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent.opacity(0.08))
            )
            .shadow(color: accent.opacity(0.45), radius: 6, x: 0, y: 0)
            .padding(2)
    }

    // MARK: - 日付インジケーター（今日 / 選択）

    @ViewBuilder private var dateIndicator: some View {
        if isSelected {
            Circle().fill(.blue)
        } else if isToday {
            Circle().fill(.red)
        }
    }

    // MARK: - ヘルパー

    private var rainText: String {
        forecast.map { String(format: "%.0f%%", $0.aiPrediction.rainProbabilityPercent) } ?? "--%"
    }

    private var temperatureText: String {
        forecast.map { String(format: "%.0f°", $0.aiPrediction.referencePastAverageTemp) } ?? "--°"
    }

    private var accessibilityText: String {
        var parts = [day.date.formatted(.dateTime.month().day()), condition.label]
        if !events.isEmpty { parts.append("予定 \(events.count)件") }
        return parts.joined(separator: ", ")
    }

    private var numberColor: Color {
        if isSelected || isToday { return .white }
        return isPast ? .secondary : .primary
    }
}

// MARK: - WeatherCondition アクセントカラー拡張

extension WeatherCondition {
    /// フィルターハイライトのリング・グロー色。
    var accentColor: Color {
        switch self {
        case .sunny:        return .yellow
        case .partlyCloudy: return Color(red: 1.0, green: 0.8, blue: 0.3)
        case .cloudy:       return Color(white: 0.6)
        case .rainy:        return .blue
        case .snowy:        return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .stormy:       return .purple
        }
    }
}
