import SwiftUI

// MARK: - CalendarDayTimelineView
//
// ⚠️ 注意: ExternalCalendarEvent の実際のプロパティ名がここでの想定
// （startDate / endDate / isAllDay）と異なる場合は、下の
// 「ヘルパー（プロパティ名の差異を吸収）」セクションだけ実際の名前に
// 書き換えれば動きます。他の箇所は変更不要です。

/// 選択日の予定を、純正カレンダーアプリのように 0:00〜23:00 の時間軸上に配置して表示する。
/// 予定が少ない・ゼロの日でも罫線グリッドが画面を埋めるので、見た目が崩れずスクロールできる。
struct CalendarDayTimelineView: View {
    var date: Date
    var events: [ExternalCalendarEvent]

    private let hourHeight: CGFloat = 64
    private let leadingGutter: CGFloat = 52
    private let calendar = Calendar.current

    private var timedEvents: [ExternalCalendarEvent] {
        events.filter { !isAllDay($0) }
    }
    private var allDayEvents: [ExternalCalendarEvent] {
        events.filter { isAllDay($0) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !allDayEvents.isEmpty {
                        allDaySection
                        Divider()
                    }

                    ZStack(alignment: .topLeading) {
                        // ── 時間の罫線（0:00〜23:00）──────────────
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                hourRow(hour)
                                    .id(hour)
                            }
                        }

                        // ── 現在時刻の赤いライン（今日のときだけ）──
                        if calendar.isDateInToday(date) {
                            nowLine
                        }

                        // ── 予定ブロック ──────────────────────────
                        GeometryReader { geo in
                            ForEach(Array(timedEvents.enumerated()), id: \.offset) { _, event in
                                eventBlock(event, containerWidth: geo.size.width)
                            }
                        }
                        .padding(.leading, leadingGutter + 6)
                        .padding(.trailing, 8)
                    }
                }
            }
            .onAppear {
                // 最初の予定がある時刻付近、なければ現在時刻付近までスクロールしておく
                let targetHour = timedEvents
                    .map { calendar.component(.hour, from: startDate($0)) }
                    .min() ?? calendar.component(.hour, from: Date())
                DispatchQueue.main.async {
                    proxy.scrollTo(max(targetHour - 1, 0), anchor: .top)
                }
            }
        }
    }

    // MARK: - 終日予定

    private var allDaySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(allDayEvents.enumerated()), id: \.offset) { _, event in
                HStack(spacing: 6) {
                    Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                    Text(event.title)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - 時間の行（罫線 + 時刻ラベル）

    private func hourRow(_ hour: Int) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(String(format: "%d:00", hour))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: leadingGutter, alignment: .trailing)
                .offset(y: -6)
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
                .offset(y: -0.5)
        }
        .frame(height: hourHeight, alignment: .top)
    }

    // MARK: - 現在時刻ライン

    private var nowLine: some View {
        let comps = calendar.dateComponents([.hour, .minute], from: Date())
        let y = CGFloat(comps.hour ?? 0) * hourHeight + CGFloat(comps.minute ?? 0) / 60 * hourHeight

        return HStack(spacing: 4) {
            Circle().fill(Color.red).frame(width: 7, height: 7)
            Rectangle().fill(Color.red).frame(height: 1.5)
        }
        .padding(.leading, leadingGutter - 3)
        .padding(.trailing, 8)
        .offset(y: y - 3)
    }

    // MARK: - 予定ブロック

    private func eventBlock(_ event: ExternalCalendarEvent, containerWidth: CGFloat) -> some View {
        let start = startDate(event)
        let end = endDate(event)

        let startComps = calendar.dateComponents([.hour, .minute], from: start)
        let startOffset = CGFloat(startComps.hour ?? 0) * hourHeight
            + CGFloat(startComps.minute ?? 0) / 60 * hourHeight

        let duration = max(end.timeIntervalSince(start), 15 * 60) // 最低15分ぶんの高さを確保
        let blockHeight = max(CGFloat(duration / 3600) * hourHeight, 22)

        return VStack(alignment: .leading, spacing: 1) {
            Text(event.title)
                .font(.caption.weight(.semibold))
                .lineLimit(blockHeight > 34 ? 2 : 1)
            if blockHeight > 34 {
                Text(start.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: max(containerWidth, 0), height: blockHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .offset(y: startOffset)
    }

    // MARK: - ヘルパー（プロパティ名の差異を吸収）
    //
    // ExternalCalendarEvent の実際のプロパティ名がこれと違う場合は、
    // ここの3行だけ実物に合わせて書き換えてください。

    private func startDate(_ event: ExternalCalendarEvent) -> Date { event.startDate }
    private func endDate(_ event: ExternalCalendarEvent) -> Date { event.endDate }
    private func isAllDay(_ event: ExternalCalendarEvent) -> Bool { event.isAllDay }
}
