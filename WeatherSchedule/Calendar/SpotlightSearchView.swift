import SwiftUI

// MARK: - SpotlightSearchView
//
// Apple の Spotlight 検索にインスパイアされた、カレンダー画面用のグローバル検索オーバーレイ。
// ・深いすりガラス背景（.ultraThinMaterial）
// ・上部に大きなクリアな検索フィールド（自動フォーカス）
// ・日付 / 天気 / 予定 をリアルタイムにサジェスト
//
// CalendarView からは `.spotlightSearchOverlay(store:externalCalendar:onSelectDate:)` で
// 1行だけ追加すれば組み込める。

struct SpotlightSearchView: View {
    var store: CalendarStore
    var externalCalendar: ExternalCalendarStore
    /// 検索結果タップ時に呼ばれる。カレンダー側で「その日にスクロール＋詳細を開く」処理を行う。
    var onSelectDate: (Date) -> Void

    @FocusState private var isFocused: Bool
    @Namespace private var animation

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }

    var body: some View {
        ZStack(alignment: .top) {
            // ── 背景：深いすりガラス。タップで閉じる ──────────────
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if store.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    emptyState
                } else if results.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
            .padding(.top, 8)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .onAppear {
            // 開いた瞬間に自動フォーカス（キーボード表示）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    // MARK: - 検索フィールド

    private var searchField: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 18, weight: .medium))

                TextField("日付・天気・予定を検索", text: Binding(
                    get: { store.searchText },
                    set: { store.searchText = $0 }
                ))
                .focused($isFocused)
                .font(.title3)
                .submitLabel(.search)
                .autocorrectionDisabled()

                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.thickMaterial)
            )

            Button("キャンセル") { close() }
                .font(.body)
        }
    }

    // MARK: - 空状態 / 未検索時のヒント

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
                .padding(.top, 60)
            Text("日付、天気、予定のタイトルで検索できます")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(["6月", "25日", "晴れ", "雨"], id: \.self) { hint in
                    Button {
                        store.searchText = hint
                    } label: {
                        Text(hint)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.thinMaterial))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
                .padding(.top, 60)
            Text("見つかりませんでした")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 結果リスト

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedResults, id: \.title) { section in
                    Text(section.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    ForEach(section.items) { item in
                        resultRow(item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                select(item)
                            }
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thickMaterial)
                .padding(.horizontal, 12)
        )
        .padding(.top, 10)
    }

    private func resultRow(_ item: SearchResultItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 選択 / クローズ

    private func select(_ item: SearchResultItem) {
        isFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            store.isSearchPresented = false
        }
        // オーバーレイが閉じるアニメーションと競合しないよう少し遅らせて遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSelectDate(item.date)
        }
    }

    private func close() {
        isFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            store.isSearchPresented = false
        }
    }

    // MARK: - 検索ロジック

    private struct SearchResultItem: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let subtitle: String
        let symbol: String
        let tint: Color
    }

    private struct ResultSection {
        let title: String
        let items: [SearchResultItem]
    }

    /// 「晴れ」「雨」等の日本語キーワード → WeatherCondition のマッピング。
    private static let weatherKeywords: [(keywords: [String], conditions: [WeatherCondition])] = [
        (["晴", "晴れ", "sunny"], [.sunny, .partlyCloudy]),
        (["曇", "くもり", "cloudy"], [.cloudy]),
        (["雨", "あめ", "rain", "rainy"], [.rainy]),
        (["雪", "ゆき", "snow", "snowy"], [.snowy]),
        (["嵐", "雷", "storm", "stormy"], [.stormy])
    ]

    private var normalizedQuery: String {
        store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// クエリから "6月" "25日" 等の日付要素を抜き出す。
    private func extractDateComponents(from query: String) -> (month: Int?, day: Int?) {
        var month: Int?
        var day: Int?

        if let monthMatch = query.range(of: #"([0-9]{1,2})\s*月"#, options: .regularExpression) {
            let digits = query[monthMatch].filter(\.isNumber)
            month = Int(digits)
        }
        if let dayMatch = query.range(of: #"([0-9]{1,2})\s*日"#, options: .regularExpression) {
            let digits = query[dayMatch].filter(\.isNumber)
            day = Int(digits)
        }
        // "月" "日" が付かない裸の数字（例: "25"）は日付として扱う
        if month == nil && day == nil, let n = Int(query), (1...31).contains(n) {
            day = n
        }
        return (month, day)
    }

    private func matchingWeatherConditions(for query: String) -> [WeatherCondition] {
        Self.weatherKeywords
            .filter { entry in entry.keywords.contains { query.contains($0.lowercased()) } }
            .flatMap(\.conditions)
    }

    private var results: [SearchResultItem] {
        let query = normalizedQuery
        guard !query.isEmpty else { return [] }

        var items: [SearchResultItem] = []
        let today = calendar.startOfDay(for: Date())

        // ── 1. 天気での検索 ──────────────────────────────
        let weatherMatches = matchingWeatherConditions(for: query)
        if !weatherMatches.isEmpty {
            let dayMatches = store.allDays
                .filter { day in
                    guard let condition = store.condition(for: day.date) else { return false }
                    return weatherMatches.contains(condition)
                }
                .sorted { abs($0.date.timeIntervalSince(today)) < abs($1.date.timeIntervalSince(today)) }
                .prefix(20)

            for day in dayMatches {
                let condition = store.condition(for: day.date)
                items.append(
                    SearchResultItem(
                        date: day.date,
                        title: day.date.formatted(.dateTime.month(.wide).day().weekday(.wide)),
                        subtitle: condition?.label ?? "天気",
                        symbol: condition?.symbol ?? "cloud",
                        tint: .blue
                    )
                )
            }
        }

        // ── 2. 日付での検索 ──────────────────────────────
        let (month, day) = extractDateComponents(from: query)
        if month != nil || day != nil {
            let dateMatches = store.allDays
                .filter { d in
                    let comps = calendar.dateComponents([.month, .day], from: d.date)
                    if let month, comps.month != month { return false }
                    if let day, comps.day != day { return false }
                    return true
                }
                .sorted { abs($0.date.timeIntervalSince(today)) < abs($1.date.timeIntervalSince(today)) }
                .prefix(20)

            for d in dateMatches {
                let condition = store.condition(for: d.date)
                items.append(
                    SearchResultItem(
                        date: d.date,
                        title: d.date.formatted(.dateTime.year().month(.wide).day()),
                        subtitle: condition?.label ?? d.date.formatted(.dateTime.weekday(.wide)),
                        symbol: "calendar",
                        tint: .indigo
                    )
                )
            }
        }

        // ── 3. 予定（イベント）での検索 ──────────────────
        let eventMatches = store.months
            .flatMap(\.days)
            .flatMap { day in
                externalCalendar.events(for: day.date).compactMap { event -> (Date, ExternalCalendarEvent)? in
                    event.title.lowercased().contains(query) ? (day.date, event) : nil
                }
            }
            .sorted { abs($0.0.timeIntervalSince(today)) < abs($1.0.timeIntervalSince(today)) }
            .prefix(20)

        for (date, event) in eventMatches {
            items.append(
                SearchResultItem(
                    date: date,
                    title: event.title,
                    subtitle: date.formatted(.dateTime.month(.abbreviated).day().hour().minute()),
                    symbol: "calendar.badge.clock",
                    tint: .orange
                )
            )
        }

        return items
    }

    /// 種別ごとにセクション分けして表示する。
    private var groupedResults: [ResultSection] {
        var sections: [ResultSection] = []

        let weatherItems = results.filter { $0.tint == .blue }
        let dateItems = results.filter { $0.tint == .indigo }
        let eventItems = results.filter { $0.tint == .orange }

        if !weatherItems.isEmpty { sections.append(.init(title: "天気", items: weatherItems)) }
        if !dateItems.isEmpty { sections.append(.init(title: "日付", items: dateItems)) }
        if !eventItems.isEmpty { sections.append(.init(title: "予定", items: eventItems)) }

        return sections
    }
}

// MARK: - CalendarView 組み込み用モディファイア

extension View {
    /// カレンダー画面に Spotlight 風検索オーバーレイを重ねる。
    /// `store.isSearchPresented` が true になったタイミングで表示される。
    func spotlightSearchOverlay(
        store: CalendarStore,
        externalCalendar: ExternalCalendarStore,
        onSelectDate: @escaping (Date) -> Void
    ) -> some View {
        self.overlay {
            if store.isSearchPresented {
                SpotlightSearchView(
                    store: store,
                    externalCalendar: externalCalendar,
                    onSelectDate: onSelectDate
                )
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.isSearchPresented)
    }
}
