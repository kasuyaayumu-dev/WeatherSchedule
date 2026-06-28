import SwiftUI

// MARK: - カードスタック本体

/// Time Machine 風の Z 軸スタックと DragGesture によるパラパラめくりアニメーション。
struct WayBackCardStack: View {
  var store: WayBackStore

  // スタック奥行き設定
  private let depthScale: CGFloat = 0.072    // 1枚ごとのスケール縮小率
  private let depthOffsetY: CGFloat = -14    // 1枚ごとの Y オフセット（奥へ）
  private let depthOffsetX: CGFloat = 0
  private let maxTilt: Double = 6            // ドラッグ時の傾き最大角度

  var body: some View {
    GeometryReader { geo in
      let cardW = geo.size.width
      let cardH = min(geo.size.height, 380.0)

      ZStack {
        ForEach(Array(store.cardYears.enumerated().reversed()), id: \.element) { index, year in
          cardView(
            year: year,
            index: index,
            cardW: cardW,
            cardH: cardH
          )
        }
      }
      .frame(width: cardW, height: cardH)
      // ドラッグジェスチャー
      .gesture(dragGesture)
    }
  }

  // MARK: - 個別カード配置

  @ViewBuilder
  private func cardView(year: Int, index: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
    let isFront = index == 0
    let dragProgress = store.dragOffset / 220  // -1.0 〜 1.0 正規化

    // 手前カードがスワイプされると次のカードが浮き上がるエフェクト
    let promotionFactor: CGFloat = isFront ? 0 : max(0, min(1, abs(dragProgress) * 1.4))
    let effectiveIndex = max(0, CGFloat(index) - promotionFactor)

    // Z軸スタックの変換
    let scale = 1.0 - effectiveIndex * depthScale
    let translateY = effectiveIndex * depthOffsetY
    let translateX = effectiveIndex * depthOffsetX

    // 手前カードのドラッグ変換
    let frontTranslateX: CGFloat = isFront ? store.dragOffset * 0.6 : 0
    let frontTranslateY: CGFloat = isFront ? abs(store.dragOffset) * 0.08 : 0
    let rotation: Double = isFront ? Double(store.dragOffset) * 0.028 : 0
    let tilt: Double = isFront
      ? max(-maxTilt, min(maxTilt, Double(store.dragOffset) * 0.04))
      : 0

    // 奥のカードの opacity
    let opacity: Double = isFront ? 1.0 : max(0.3, 1.0 - Double(index) * 0.18)

    WayBackCard(
      year: year,
      month: store.referenceMonth,
      day: store.referenceDay,
      isFront: isFront,
      depthIndex: index
    )
    .frame(width: cardW, height: cardH)
    .scaleEffect(scale)
    .rotation3DEffect(.degrees(tilt), axis: (x: 0, y: 1, z: 0))
    .rotationEffect(.degrees(rotation))
    .offset(x: translateX + frontTranslateX, y: translateY + frontTranslateY)
    .opacity(opacity)
    .zIndex(Double(store.visibleCardCount - index))
    .animation(
      isFront ? .interactiveSpring(response: 0.28, dampingFraction: 0.72) : .spring(response: 0.38, dampingFraction: 0.8),
      value: store.dragOffset
    )
    .animation(.spring(response: 0.42, dampingFraction: 0.82), value: store.selectedYear)
  }

  // MARK: - DragGesture

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged { value in
        guard !store.isTransitioning else { return }
        // 左右スワイプのみ受け付け
        let horizontal = value.translation.width
        let vertical = value.translation.height
        guard abs(horizontal) > abs(vertical) * 0.5 else { return }
        store.dragOffset = horizontal
      }
      .onEnded { value in
        let velocity = value.predictedEndTranslation.width - value.translation.width
        store.commitSwipe(velocity: velocity)
      }
  }
}

// MARK: - スワイプヒント

/// 初回表示時にスワイプ方向を示すアニメーションヒント。
struct SwipeHintView: View {
  @State private var animate = false

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "chevron.left")
        .opacity(animate ? 0.25 : 0.7)
      Text("スワイプで年移動")
        .font(.caption)
        .foregroundStyle(.secondary)
      Image(systemName: "chevron.right")
        .opacity(animate ? 0.7 : 0.25)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .onAppear {
      withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.3)) {
        animate = true
      }
    }
  }
}
