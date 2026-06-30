import SwiftUI

// MARK: - AI インサイト生成ロジック
//
// DayDetailView が開かれるたびに ForecastResponse の数値と日付から
// パーソナライズドメッセージを生成する。
// 実装は純粋な Swift 側で完結させ、Anthropic API は呼ばない
// （ネットワーク不要 / API キー不要）。
// ロジックは「条件木 + テンプレート文」で構成し、
// 組み合わせ爆発により実質的にランダムな文章を生成する。

struct AIInsightGenerator {

    // MARK: 生成エントリーポイント

    static func generate(for date: Date, forecast: ForecastResponse) -> AIInsight {
        let rain   = forecast.aiPrediction.rainProbabilityPercent
        let temp   = forecast.aiPrediction.referencePastAverageTemp
        let humid  = forecast.aiPrediction.referencePastAverageHumidity
        let score  = calculateScore(rain: rain, temp: temp)

        let condition = WeatherCondition.from(rainProbability: rain, temperature: temp)
        let holiday   = japaneseHoliday(for: date)
        let season    = Season(from: date)
        let timeOfDay = DayPart(from: date)

        let lead    = leadSentence(condition: condition, rain: rain, temp: temp, holiday: holiday)
        let body    = bodySentence(season: season, humid: humid, score: score)
        let closing = closingSentence(condition: condition, holiday: holiday, timeOfDay: timeOfDay)

        return AIInsight(
            headline: headline(condition: condition, score: score, holiday: holiday),
            message: [lead, body, closing].joined(separator: " "),
            badge: badge(score: score),
            scoreColor: scoreColor(score)
        )
    }
    private static func calculateScore(rain: Double, temp: Double) -> Int {
            var score = 5
            
            // 降水確率による減点
            if rain >= 80 {
                score -= 3
            } else if rain >= 50 {
                score -= 2
            } else if rain >= 30 {
                score -= 1
            }
            
            // 気温による減点（極端な暑さ・寒さ）
            if temp >= 35 || temp <= 0 {
                score -= 2
            } else if temp >= 30 || temp <= 5 {
                score -= 1
            }
            
            // 1〜5の範囲に収める
            return max(1, min(5, score))
        }

    // MARK: - 見出し

    private static func headline(condition: WeatherCondition,
                                  score: Int,
                                  holiday: String?) -> String {
        if let h = holiday { return "\(h)の天気予測" }
        switch condition {
        case .sunny:  return score >= 4 ? "絶好のイベント日和です" : "おおむね晴れる見込み"
        case .cloudy: return "曇りがちな一日"
        case .partlyCloudy:  return "部分的に曇る"
        case .rainy:  return "雨への備えを"
        case .snowy:  return "雪の日のプランニング"
        case .stormy: return "荒天に注意が必要です"
        }
    }

    // MARK: - リード文

    private static func leadSentence(condition: WeatherCondition,
                                      rain: Double,
                                      temp: Double,
                                      holiday: String?) -> String {
        let tempStr = String(format: "%.0f", temp)
        let rainStr = String(format: "%.0f", rain)
        let prefix  = holiday.map { "\($0)の" } ?? ""

        switch condition {
        case .sunny:
            return "\(prefix)この日の降水確率は\(rainStr)%と低く、平均気温\(tempStr)°の過ごしやすい晴天が期待できます。"
        case .cloudy:
            return "\(prefix)曇り空が広がる見込みで、降水確率は\(rainStr)%です。気温は\(tempStr)°前後を推移するでしょう。"
        case .partlyCloudy:
            return "\(prefix)曇りが少なく、降水確率は\(rainStr)%です。気温は\(tempStr)°と比較的良い予報です。"
        case .rainy:
            return "\(prefix)降水確率\(rainStr)%と雨の可能性が高い一日です。気温は\(tempStr)°と比較的\(temp < 15 ? "低め" : "穏やか")な予報です。"
        case .snowy:
            return "\(prefix)気温\(tempStr)°まで下がる予報で、降水確率\(rainStr)%の雪の可能性があります。"
        case .stormy:
            return "\(prefix)嵐の気配があります。降水確率は\(rainStr)%、強雨・強風への備えが必要です。"
        }
    }

    // MARK: - 本文（季節・湿度・スコア）

    private static func bodySentence(season: Season, humid: Double, score: Int) -> String {
        let humidDesc: String
        switch humid {
        case ..<40:  humidDesc = "湿度が低く快適な"
        case 40..<65: humidDesc = "湿度もほどよい"
        default:      humidDesc = "湿度がやや高めの"
        }

        let seasonHint: String
        switch season {
        case .spring: seasonHint = "花粉の飛散が気になる時期ですが、"
        case .summer: seasonHint = "熱中症対策をしっかり行い、"
        case .autumn: seasonHint = "秋晴れの気持ちよい季節です。"
        case .winter: seasonHint = "防寒対策をしっかりして、"
        }

        let scoreHint = score >= 4
            ? "イベントの実施に非常に適した条件が揃っています。"
            : score >= 3
            ? "イベントの開催は概ね問題ありません。"
            : "屋内プランや代替日程の検討をお勧めします。"

        return "\(humidDesc)コンディションの中、\(seasonHint)\(scoreHint)"
    }

    // MARK: - クロージング（時間帯・休日）

    private static func closingSentence(condition: WeatherCondition,
                                         holiday: String?,
                                         timeOfDay: DayPart) -> String {
        let prefix: String
        switch timeOfDay {
        case .morning: prefix = "朝の準備段階で"
        case .afternoon: prefix = "お昼過ぎには"
        case .evening: prefix = "夕方にかけて"
        case .night: prefix = "翌朝に向けて"
        }

        if let _ = holiday {
            switch condition {
            case .sunny:  return "\(prefix)お出かけに最高のタイミングです。素敵な休日をお過ごしください。"
            case .rainy, .stormy: return "\(prefix)室内でのプランも視野に入れてみてください。"
            default:      return "\(prefix)お気をつけてお過ごしください。"
            }
        }

        switch condition {
        case .sunny:   return "\(prefix)日差しを活用したアウトドアアクティビティがはかどるでしょう。"
        case .cloudy:  return "\(prefix)天候が変わりやすいため、念のため傘の携帯を。"
        case .partlyCloudy: return "\(prefix)天候が変わりやすいため、念のため傘の携帯を。"
        case .rainy:   return "\(prefix)雨具と防水対策をしっかり準備しておきましょう。"
        case .snowy:   return "\(prefix)路面の凍結に注意し、余裕を持ったスケジュールで。"
        case .stormy:  return "\(prefix)不要不急の外出は控えることをお勧めします。"
        }
    }

    // MARK: - バッジ

    private static func badge(score: Int) -> String {
        switch score {
        case 5: return "⭐ イベント日和"
        case 4: return "✅ 良好"
        case 3: return "🔶 まあまあ"
        case 2: return "⚠️ 要注意"
        default: return "🚫 非推奨"
        }
    }

    private static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 5: return .yellow
        case 4: return .green
        case 3: return .orange
        case 2: return Color(red: 1, green: 0.5, blue: 0)
        default: return .red
        }
    }

    // MARK: - 日本の祝日（主要な日のみ）

    private static func japaneseHoliday(for date: Date) -> String? {
        let cal = Calendar.current
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)

        let fixed: [String: String] = [
            "1-1": "元日", "2-11": "建国記念の日", "2-23": "天皇誕生日",
            "4-29": "昭和の日", "5-3": "憲法記念日", "5-4": "みどりの日",
            "5-5": "こどもの日", "8-11": "山の日", "11-3": "文化の日",
            "11-23": "勤労感謝の日", "12-23": "天皇誕生日(旧)", "12-25": "クリスマス"
        ]
        return fixed["\(m)-\(d)"]
    }
}

// MARK: - 補助型

struct AIInsight {
    var headline: String
    var message: String
    var badge: String
    var scoreColor: Color
}

private enum Season {
    case spring, summer, autumn, winter
    init(from date: Date) {
        let m = Calendar.current.component(.month, from: date)
        switch m {
        case 3...5: self = .spring
        case 6...8: self = .summer
        case 9...11: self = .autumn
        default:    self = .winter
        }
    }
}

private enum DayPart {
    case morning, afternoon, evening, night
    init(from date: Date) {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case 5...11:  self = .morning
        case 12...17: self = .afternoon
        case 18...21: self = .evening
        default:      self = .night
        }
    }
}

// MARK: - AIInsightCard View

/// DayDetailView に埋め込む Apple Intelligence 風カード。
struct AIInsightCard: View {
    var date: Date
    var forecast: ForecastResponse

    @State private var insight: AIInsight?
    @State private var isExpanded = false

    var body: some View {
        Group {
            if let insight {
                content(insight)
            } else {
                generatingPlaceholder
            }
        }
        .task(id: forecast.requestDate) {
            // 少し遅らせることでアニメーションが映える
            try? await Task.sleep(nanoseconds: 180_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                insight = AIInsightGenerator.generate(for: date, forecast: forecast)
            }
        }
    }

    // MARK: - 生成中プレースホルダー

    private var generatingPlaceholder: some View {
        HStack(spacing: 10) {
            // Apple Intelligence 風オーロラリング
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(colors: [
                            Color(red: 0.95, green: 0.4, blue: 0.9),
                            Color(red: 0.4,  green: 0.6, blue: 1.0),
                            Color(red: 0.3,  green: 0.9, blue: 0.8),
                            Color(red: 0.95, green: 0.4, blue: 0.9),
                        ], center: .center)
                    )
                    .frame(width: 28, height: 28)
                    .symbolEffect(.pulse)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("AIが分析しています…")
                    .font(.subheadline.weight(.medium))
                Text("気象データと祝日情報を組み合わせ中")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - メインカード

    private func content(_ insight: AIInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // ── ヘッダー行 ──────────────────────────────────
            HStack(alignment: .top, spacing: 10) {
                // Aurora orb
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(colors: [
                                Color(red: 0.95, green: 0.4, blue: 0.9),
                                Color(red: 0.4,  green: 0.6, blue: 1.0),
                                Color(red: 0.3,  green: 0.9, blue: 0.8),
                                Color(red: 0.95, green: 0.4, blue: 0.9),
                            ], center: .center)
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: Color(red: 0.7, green: 0.4, blue: 1.0).opacity(0.4), radius: 8)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.headline)
                        .font(.subheadline.weight(.semibold))
                    Text("AI気象アドバイス")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // スコアバッジ
                Text(insight.badge)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(insight.scoreColor.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(insight.scoreColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(insight.scoreColor)
            }

            Divider()

            // ── メッセージ本文 ──────────────────────────────
            Text(insight.message)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            if !isExpanded {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                } label: {
                    Text("続きを読む")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }
        }
        .padding(14)
        .background(
            // Aurora グラデーション border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.7, green: 0.4, blue: 1.0).opacity(0.4),
                                    Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.3),
                                    Color(red: 0.3, green: 0.9, blue: 0.8).opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.97)),
            removal: .opacity
        ))
    }
}
