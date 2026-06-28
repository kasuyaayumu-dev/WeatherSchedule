import SwiftUI

// MARK: - Way Back メインオーバーレイ

/// Way Back モード全体のオーバーレイビュー。
/// `CalendarView` の `.overlay` として重ねることで、カレンダーをブラーした上に表示する。
struct WayBackView: View {
  var store: WayBackStore

  /// カレンダーから渡す選択中の日付（nil なら今日を使う）。
  var referenceDate: Date?

  var body: some View {
    ZStack {
      // 背景ブラー（カレンダーを透かす）
      Rectangle()
        .fill(.ultraThinMaterial)
        .ignoresSafeArea()
        .onTapGesture { store.close() }

      VStack(spacing: 0) {
        // ナビゲーションヘッダー
        header

        Spacer(minLength: 0)

        // カードスタック
        WayBackCardStack(store: store)
          .padding(.horizontal, 24)
          .frame(height: 380)

        Spacer(minLength: 16)

        // 年スクラバー
        YearScrubberView(store: store)
          .padding(.horizontal, 16)

        Spacer(minLength: 8)

        // スワイプヒント
        SwipeHintView()
          .padding(.bottom, 8)

        // 下部の安全領域
        Color.clear.frame(height: 16)
      }
      .padding(.top, 12)
    }
  }

  // MARK: - ヘッダー

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Label("Way Back", systemImage: "clock.arrow.circlepath")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        if let date = referenceDate ?? makeReferenceDate() {
          Text(date.formatted(.dateTime.month(.wide).day()))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
      Button(action: { store.close() }) {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
          .symbolRenderingMode(.hierarchical)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Way Backを閉じる")
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
  }

  private func makeReferenceDate() -> Date? {
    guard let day = store.referenceDay else { return nil }
    var comps = DateComponents()
    comps.year = Calendar.current.component(.year, from: Date())
    comps.month = store.referenceMonth
    comps.day = day
    return Calendar.current.date(from: comps)
  }
}

// MARK: - 年スクラバー

/// タイムライン状の年リスト。タップでカードをジャンプ選択できる。
struct YearScrubberView: View {
  var store: WayBackStore

  private var years: [Int] {
    (store.minYear...store.maxYear).reversed()
  }

  var body: some View {
    VStack(spacing: 8) {
      Text("タップで年を選択")
        .font(.caption2)
        .foregroundStyle(.quaternary)

      ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 10) {
            ForEach(years, id: \.self) { year in
              yearPill(year: year)
                .id(year)
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
        }
        .onAppear {
          withAnimation {
            proxy.scrollTo(store.selectedYear, anchor: .center)
          }
        }
        .onChange(of: store.selectedYear) { _, newYear in
          withAnimation(.spring(response: 0.35)) {
            proxy.scrollTo(newYear, anchor: .center)
          }
        }
      }
    }
    .padding(.vertical, 6)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(.quaternary, lineWidth: 0.5)
    }
  }

  private func yearPill(year: Int) -> some View {
    let isSelected = year == store.selectedYear
    let summary = HistoricalDataStub.monthSummary(year: year, month: store.referenceMonth)

    return Button {
      store.selectYear(year)
    } label: {
      VStack(spacing: 4) {
        Image(systemName: summary.dominantCondition.symbol)
          .symbolRenderingMode(.multicolor)
          .font(.caption)
          .opacity(isSelected ? 1 : 0.55)

        Text("\(year)")
          .font(.caption.weight(isSelected ? .bold : .regular))
          .monospacedDigit()
          .foregroundStyle(isSelected ? .primary : .secondary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background {
        if isSelected {
          Capsule()
            .fill(summary.dominantCondition.tint.opacity(0.22))
            .overlay(Capsule().strokeBorder(summary.dominantCondition.tint.opacity(0.5), lineWidth: 1))
        }
      }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .animation(.spring(response: 0.3), value: store.selectedYear)
  }
}

// MARK: - CalendarView への統合用 Modifier

extension View {
  /// Way Back オーバーレイを付与するモディファイア。
  func wayBackOverlay(store: WayBackStore, referenceDate: Date? = nil) -> some View {
    self.overlay {
      if store.isPresented {
        WayBackView(store: store, referenceDate: referenceDate)
          .transition(
            .asymmetric(
              insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .bottom)),
              removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .bottom))
            )
          )
      }
    }
    .animation(.spring(response: 0.42, dampingFraction: 0.86), value: store.isPresented)
  }
}
