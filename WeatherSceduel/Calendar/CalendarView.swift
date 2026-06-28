import SwiftUI

/// メイン画面。月ごとの縦スクロールカレンダー＋選択詳細ビュー。
struct CalendarView: View {
  var store: CalendarStore

  @State private var showSettings = false
  // ★ Way Back ストアを追加
  @State private var wayBack = WayBackStore()

  private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

  var body: some View {
    @Bindable var store = store

    VStack(spacing: 0) {
      // ★ onWayBack クロージャを渡す
      TopBarView(title: store.navigationTitle, onSettings: { showSettings = true }) {
        wayBack.open(referenceDate: store.selectedDate)
      }
      weekdayHeader
      Divider()

      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(store.months) { month in
            CalendarMonthView(
              month: month,
              condition: { store.condition(for: $0.date) ?? $0.condition },
              isSelected: { store.isSelected($0) }
            ) { day in
              withAnimation(.snappy) { store.toggleSelection(day) }
            }
            .id(month.id)
          }
        }
        .padding(.bottom, store.selectedDay == nil ? 16 : 320)
        .scrollTargetLayout()
      }
      .scrollPosition(id: $store.visibleMonthID, anchor: .top)
    }
    .background(Color(.systemGroupedBackground))
    .overlay(alignment: .bottom) {
      if let day = store.selectedDay {
        DayDetailView(
          date: day.date,
          state: store.forecastState,
          onClose: { withAnimation(.snappy) { store.clearSelection() } },
          onRetry: { store.retry() }
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    // ★ Way Back オーバーレイを付与
    .wayBackOverlay(store: wayBack, referenceDate: store.selectedDate)
    .onAppear {
      DispatchQueue.main.async {
        store.visibleMonthID = store.todayMonthID
      }
      store.prefetchMonth(id: store.todayMonthID)
    }
    .onChange(of: store.visibleMonthID) { _, newID in
      store.prefetchMonth(id: newID)
    }
    .sheet(isPresented: $showSettings) {
      SettingsView()
    }
  }

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
