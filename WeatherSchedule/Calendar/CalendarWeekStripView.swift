import SwiftUI

/// 日付詳細モーダルを半展開（.medium）しているときに背景へ表示する「週ストリップ」。
/// ネイティブ Calendar アプリの日表示ヘッダーのように、選択日を含む週の 7 日間を横並びで表示し、
/// 左右スワイプ（またはタップ）で選択日を切り替えられる。
///
/// フル展開時や未選択時は使わず、CalendarView 側で月グリッドと出し分ける。
struct CalendarWeekStripView: View {
    var selectedDate: Date
    var events: (Date) -> [ExternalCalendarEvent]
    /// タップで直接その日を選択
    var onSelect: (Date) -> Void
    /// 横スワイプでの日送り（-1: 前日 / +1: 翌日）
    var onSwipeDay: (Int) -> Void
    /// 予定 → 月 に戻るときの右への大きいスワイプで呼ばれる
    var onSwipeBackToMonth: () -> Void = {}

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }

    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    private var weekDays: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── 曜日 + 日付の週ストリップ ─────────────────────
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(weekdayColor(index))
                            .frame(maxWidth: .infinity)
                    }
                }
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { date in
                        dayCell(date)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(calendar.startOfDay(for: date))
                            }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 10)
            // ほぼ水平方向の指の動きだけを「日送りスワイプ」とみなす（誤爆防止）。
            // さらに大きく右へスワイプしたときは「月表示へ戻る」とみなす。
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > abs(dy) * 1.5 else { return }

                        if dx > 130 {
                            // 大きく右にスワイプ → 予定表示から月表示へ戻る
                            onSwipeBackToMonth()
                        } else if abs(dx) > 40 {
                            onSwipeDay(dx < 0 ? 1 : -1)
                        }
                    }
            )

            Divider()

            // ── その日の予定：時間軸タイムライン ────────────────
            CalendarDayTimelineView(
                date: selectedDate,
                events: events(selectedDate)
            )
        }
    }

    // MARK: - 日付セル

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        Text("\(day)")
            .font(.title3.weight(isSelected ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(textColor(isSelected: isSelected, isToday: isToday))
            .frame(width: 36, height: 36)
            .background(
                Circle().fill(isSelected ? Color.primary : Color.clear)
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func textColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return Color(.systemBackground) } // 選択中は円の上に白抜き文字
        if isToday { return .red }
        return .primary
    }

    private func weekdayColor(_ index: Int) -> Color {
        if index == 0 { return .red }
        if index == 6 { return .blue }
        return .secondary
    }
}
