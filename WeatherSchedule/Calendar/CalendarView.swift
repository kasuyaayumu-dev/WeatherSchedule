import SwiftUI

/// メイン画面。
/// ZStack 構造:
///   1. VStack (TopBar + ScrollView カレンダー本体)
///   2. フローティングバー (Today / AI Chat)
///   3. Way Back オーバーレイ (isPresented 時のみ)
struct CalendarView: View {
    var store: CalendarStore
    
    @AppStorage(CalendarDisplaySettings.modeKey) private var displayModeRawValue = CalendarDisplaySettings.defaultMode
    @AppStorage(CalendarDisplaySettings.weatherFilterKey) private var weatherFilterRawValue = CalendarDisplaySettings.defaultWeatherFilter
    @State private var showSettings = false
    @State private var wayBack = WayBackStore()
    @State private var externalCalendar = ExternalCalendarStore()
    
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        @Bindable var store = store
        
        ZStack(alignment: .bottom) {
            // ── 1. カレンダー本体 ──────────────────────────────
            VStack(spacing: 0) {
                TopBarView(
                    title: store.navigationTitle,
                    onSettings: { showSettings = true }
                )
                
                weekdayHeader
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.months) { month in
                            CalendarMonthView(
                                month: month,
                                condition: { store.condition(for: $0.date) ?? $0.condition },
                                forecast: { store.forecast(for: $0.date) },
                                events: { externalCalendar.events(for: $0.date) },
                                displayMode: displayMode,
                                weatherFilter: weatherFilter,
                                isSelected: { store.isSelected($0) }
                            ) { day in
                                withAnimation(.snappy) { store.toggleSelection(day) }
                            }
                            .id(month.id)
                        }
                    }
                    .padding(.bottom, 88)
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $store.visibleMonthID, anchor: .top)
            }
            .background(Color(.systemGroupedBackground))
            
            // ── 2. フローティングバー ─────────────────────────
            floatingBar(store: store)
        }
        // ── 4. Way Back オーバーレイ ──────────────────────
//        .wayBackOverlay(store: wayBack, referenceDate: store.selectedDate)
        .wayBackFullScreen(store: wayBack, referenceDate: store.selectedDate)
        .onAppear {
            DispatchQueue.main.async {
                store.visibleMonthID = store.todayMonthID
            }
            store.prefetchMonth(id: store.todayMonthID)
            refreshExternalCalendarIfNeeded(store: store)
        }
        .onChange(of: store.visibleMonthID) { _, newID in
            store.prefetchMonth(id: newID)
        }
        .onChange(of: displayModeRawValue) { _, _ in
            refreshExternalCalendarIfNeeded(store: store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(externalCalendar: externalCalendar) {
                refreshExternalCalendarIfNeeded(store: store, force: true)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.selectedDay != nil },
                set: { isPresented in
                    if !isPresented {
                        store.clearSelection()
                    }
                }
            )
        ) {
            if let day = store.selectedDay {
                DayDetailView(
                    date: day.date,
                    state: store.forecastState,
                    onClose: { store.clearSelection() },
                    onRetry: { store.retry() },
                    onWayBack: {
                        let referenceDate = day.date
                        store.clearSelection()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            wayBack.open(referenceDate: referenceDate)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var displayMode: CalendarDisplayMode {
        CalendarDisplayMode(rawValue: displayModeRawValue) ?? .weatherIcon
    }
    
    private var weatherFilter: CalendarWeatherFilter {
        CalendarWeatherFilter(rawValue: weatherFilterRawValue) ?? .all
    }
    
    private func refreshExternalCalendarIfNeeded(store: CalendarStore, force: Bool = false) {
        guard force || displayMode == .schedule else { return }
        Task { await externalCalendar.refresh(months: store.months) }
    }
    
    // MARK: - フローティングバー
    
    @ViewBuilder
    private func floatingBar(store: CalendarStore) -> some View {
        HStack(spacing: 16) {
            // Today ボタン
            Button {
                store.scrollToTodayMonth()
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
            
            // AI Chat ボタン（Apple Intelligence 風）
            Button {
                print("AI Chat tapped")
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.4, blue: 0.9),
                                    Color(red: 0.4, green: 0.6, blue: 1.0),
                                    Color(red: 0.3, green: 0.9, blue: 0.8),
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
        .padding(.bottom, 8)
    }
    
    // MARK: - 曜日ヘッダー
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}
