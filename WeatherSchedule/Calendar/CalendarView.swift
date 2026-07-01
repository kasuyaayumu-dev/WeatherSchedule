import SwiftUI

// MARK: - CalendarView（v2）
//
// 変更点:
//   • モーダル表示中もカレンダーを操作できるよう sheet → ZStack/Overlay に切り替えを検討。
//     → ただし EKEventEditView 等のシステム sheet との相性を保つため、
//       DayDetailView は引き続き sheet で表示しつつ、
//       ミニプレーヤーのみを下部 Overlay で管理する構成を採用。
//   • MiniPlayerState を @State で持ち、モーダル → ミニプレーヤーの遷移を制御。
//   • フィルター未使用時は isFilteredOut=false で統一（ハイライト方式に対応）。
//   • デバッグモードフラグを参照（CalendarStore 経由）。

// MARK: - CalendarView（v2）

struct CalendarView: View {
    var store: CalendarStore
    
    @AppStorage(CalendarDisplaySettings.modeKey)
    private var displayModeRawValue = CalendarDisplaySettings.defaultMode
    
    @AppStorage(CalendarDisplaySettings.weatherFilterKey)
    private var weatherFilterRawValue = CalendarDisplaySettings.defaultWeatherFilter
    
    @AppStorage(DebugSettings.miniPlayerAppStorageKey)
    private var miniPlayerEnabled = true
    
    @State private var showSettings    = false
    @State private var wayBack         = WayBackStore()
    @State private var externalCalendar = ExternalCalendarStore()
    @State private var miniPlayer      = MiniPlayerState()
    @State private var animateGradient = false
    
    /// DayDetailView シートの現在の高さ。Way Back を閉じた直後に .medium へ戻すために使う。
    @State private var detailDetent: PresentationDetent = .large
    
    /// ハーフモーダル（.medium）時に背景をどちらで見せるか。
    /// ユーザーがセグメントで手動切り替えする（自動では切り替えない）。
    @State private var backgroundMode: BackgroundMode = .month
    
    private var isFilterActive: Bool {
        weatherFilter != .all
    }
    
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    /// ハーフモーダル時の背景表示モード。
    private enum BackgroundMode: String, CaseIterable {
        case month = "月"
        case daySchedule = "予定"
    }
    
    var body: some View {
        @Bindable var store = store
        
        ZStack(alignment: .bottom) {
            // ── 1. カレンダー本体 ──────────────────────────────
            // 日付詳細モーダルが半展開（.medium）で選択中のときは、
            // 月グリッドの代わりにネイティブ Calendar 風の「週ストリップ + 予定リスト」を出す。
            // フル展開時（背景操作不可）や未選択時は、これまで通り月グリッドを表示する。
            VStack(spacing: 0) {
                TopBarView(
                    title: store.navigationTitle,
                    onSettings: { showSettings = true }
                )
                
                // ── ハーフモーダル中だけ出る「月／予定」切り替えセグメント ──
                if store.selectedDate != nil, detailDetent == .medium {
                    Picker("表示切り替え", selection: $backgroundMode) {
                        ForEach(BackgroundMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                
                if let selectedDate = store.selectedDate, detailDetent == .medium, backgroundMode == .daySchedule {
                    CalendarWeekStripView(
                        selectedDate: selectedDate,
                        events: { externalCalendar.events(for: $0) },
                        onSelect: { date in
                            withAnimation(.snappy) {
                                store.toggleSelection(CalendarDay(date: date))
                            }
                        },
                        onSwipeDay: { offset in
                            withAnimation(.snappy) {
                                store.selectAdjacentDay(offset)
                            }
                            HapticsManager.monthChanged()
                        },
                        onSwipeBackToMonth: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                backgroundMode = .month
                            }
                            HapticsManager.monthChanged()
                        }
                    )
                    .transition(.opacity)
                } else {
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
                        .padding(.bottom, miniPlayer.isVisible ? 140 : 88)
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $store.visibleMonthID, anchor: .top)
                    .transition(.opacity)
                    // ── ハーフモーダル中：月 → 予定 への切り替えスワイプ（左） ──
                    // 縦スクロールと衝突しないよう、ほぼ水平方向の指の動きのときだけ反応する。
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 24)
                            .onEnded { value in
                                guard store.selectedDate != nil, detailDetent == .medium else { return }
                                let dx = value.translation.width
                                let dy = value.translation.height
                                guard abs(dx) > abs(dy) * 1.5, dx < -60 else { return }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    backgroundMode = .daySchedule
                                }
                                HapticsManager.monthChanged()
                            }
                    )
                }
            }
            .background(Color(.systemGroupedBackground))
            .animation(.easeInOut(duration: 0.2), value: detailDetent)
            .animation(.easeInOut(duration: 0.2), value: backgroundMode)
            
            // ── 2. フローティングバー / ミニプレーヤー ────────
            bottomArea(store: store)
        }
        // ── 3. Way Back オーバーレイ ──────────────────────────
        .wayBackFullScreen(store: wayBack, referenceDate: store.selectedDate)
        .onAppear {
            DispatchQueue.main.async {
                store.visibleMonthID = store.todayMonthID
            }
            store.prefetchMonth(id: store.todayMonthID)
            refreshExternalCalendarIfNeeded(store: store)
        }
        // 🌟追加: 新しいセルが選択されたらミニプレイヤーを閉じる
        .onChange(of: store.selectedDay) { _, newDay in
            if newDay != nil && miniPlayer.isVisible {
                miniPlayer.hide()
            }
            if newDay != nil {
                detailDetent = .medium
            } else {
                backgroundMode = .month
            }
        }
        // 🌟追加: 週ストリップ表示（.medium）に入るタイミングで予定を読み込んでおく
        // （表示モードが天気アイコン等で、予定データ未取得のことがあるため）
        .onChange(of: detailDetent) { _, newDetent in
            if newDetent == .medium {
                Task { await externalCalendar.refresh(months: store.months) }
            }
        }
        .onChange(of: store.visibleMonthID) { _, newID in
            store.prefetchMonth(id: newID)
            HapticsManager.monthChanged()
        }
        .onChange(of: displayModeRawValue) { _, _ in
            refreshExternalCalendarIfNeeded(store: store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(externalCalendar: externalCalendar) {
                refreshExternalCalendarIfNeeded(store: store, force: true)
            }
        }
        // ── 4. DayDetailView シート ────────────────────────────
        .sheet(
                    isPresented: Binding(
                        get: { store.selectedDay != nil && !miniPlayer.isVisible },
                        set: { isPresented in
                            // 🌟修正: スワイプで閉じた時は clearSelection せずにミニプレイヤーを表示
                            if !isPresented {
                                if miniPlayerEnabled,
                                   case .loaded(let forecast) = store.forecastState,
                                   let date = store.selectedDate {
                                    miniPlayer.show(forecast: forecast, date: date)
                                } else {
                                    store.clearSelection()
                                }
                            }
                        }
                    )
                ) {
                    if let day = store.selectedDay {
                        DayDetailView(
                            date: day.date,
                            state: store.forecastState,
                            onClose: {
                                // 🌟修正: 完了ボタンで閉じたときは完全にクリアする
                                store.clearSelection()
                                miniPlayer.hide()
                            },
                            onRetry: { store.retry() },
                            onWayBack: {
                                // Way Back が閉じられたら、シートをハーフサイズへ戻す
                                wayBack.onDismiss = {
                                    detailDetent = .medium
                                }
                                wayBack.open(referenceDate: day.date)
                                HapticsManager.wayBackToggled()
                            },
                            onMinimize: miniPlayerEnabled ? {
                                if case .loaded(let forecast) = store.forecastState {
                                    miniPlayer.show(forecast: forecast, date: day.date)
                                    // 選択日を保持したまま閉じる（isPresentedがfalseになる）
                                }
                            } : nil
                        )
                        .presentationDetents([.medium, .large], selection: $detailDetent)
                        .presentationDragIndicator(.visible)
                        
                        // 🌟 ここを追加！ハーフサイズ（.medium）までの高さのとき、背後のカレンダーの操作を許可する
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    }
                }
    }
    
    // MARK: - 下部エリア（ミニプレーヤー or フローティングバー）
    
    // ... 以降のコードは変更なし ...
    
    // MARK: - 下部エリア（ミニプレーヤー or フローティングバー）
    
    @ViewBuilder
    private func bottomArea(store: CalendarStore) -> some View {
        if miniPlayer.isVisible,
           let forecast = miniPlayer.forecast,
           let date = miniPlayer.date {
            MiniPlayerBar(
                forecast: forecast,
                date: date,
                onExpand: {
                    // ミニプレーヤーを非表示にしてモーダルを再表示
                    miniPlayer.hide()
                },
                onDismiss: {
                    miniPlayer.clear()
                    store.clearSelection()
                },
                onTodayTap: {
                    store.scrollToTodayMonth()
                },
                onAIChatTap: {
                    print("AI Chat tapped from mini player")
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
        } else if !miniPlayer.isVisible {
            floatingBar(store: store)
                .transition(.opacity)
        }
    }
    
    // MARK: - フローティングバー（通常時）
    
    @ViewBuilder
    private func floatingBar(store: CalendarStore) -> some View {
        HStack(spacing: 16) {
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
            
            Button {
                print("AI Chat tapped")
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.4, blue: 0.9),
                                    Color(red: 0.4,  green: 0.6, blue: 1.0),
                                    Color(red: 0.3,  green: 0.9, blue: 0.8)
                                ],
                                // 🌟 こちらも同様に近づけたり離したりを繰り返す
                                startPoint: animateGradient ? UnitPoint(x: 0.1, y: 0.1) : UnitPoint(x: -0.3, y: -0.3),
                                endPoint: animateGradient ? UnitPoint(x: 0.9, y: 0.9) : UnitPoint(x: 1.3, y: 1.3)
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.7, green: 0.4, blue: 1.0).opacity(0.5), radius: 10, y: 4)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("AIチャット")
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animateGradient = true
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
    
    // MARK: - ヘルパー
    
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
}
