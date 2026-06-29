import SwiftUI

// MARK: - Time Machine カードスタック

struct WayBackCardStack: View {
    var store: WayBackStore
    
    private let scaleStep:   CGFloat = 0.115
    private let yStep:       CGFloat = 58
    private let opacityStep: Double  = 0.18
    
    // 手前カードが下へスライドする最大量 (pt)
    // blend=1.0 のとき frontSlideDown pt 下にずれて消える
    private let frontSlideDown: CGFloat = 120
    
    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H: CGFloat = 340
            
            ZStack(alignment: .bottom) {
                ForEach(Array(store.cardYears.enumerated()), id: \.element) { slot, year in
                    cardLayer(year: year, slot: slot, W: W, H: H)
                }
            }
            .frame(width: W, height: H + yStep * CGFloat(store.visibleCardCount - 1) + 20)
            .drawingGroup()
        }
    }
    
    @ViewBuilder
    private func cardLayer(year: Int, slot: Int, W: CGFloat, H: CGFloat) -> some View {
        let blend = store.blendFraction   // 0.0〜1.0、下スクロールで 0→1 に増加
        
        // 奥行き深度（手前カードが沈むほど奥カードが浮かぶ）
        let depth  = max(0, CGFloat(slot) - blend)
        let isFrontCard = slot == 0
        
        // ── 基本トランスフォーム（全カード共通）──
        let scale   = max(0.01, 1.0 - depth * scaleStep)
        let shiftY  = depth * yStep
        // ── opacity ──
        // 奥行きによる基本フェード（全カード共通）
        let baseOpacity = max(0.0, 1.0 - Double(depth) * opacityStep)
        
        // 最前面カード（消える）: blend 0→1 でフェードアウト
        // slot=1（現れる）:       blend 0→1 でフェードイン（depth = 1-blend なので自動的に反映）
        // それ以外はbaseOpacityのまま
        let opacity: Double = {
            if isFrontCard {
                // フェードアウト: blend が大きいほど透明に
                return baseOpacity * Double(1.0 - blend)
            } else if slot == 0 {
                // フェードイン: blend が大きいほど不透明に
                return baseOpacity * Double(blend)
            } else {
                return baseOpacity
            }
        }()
        let tiltX   = min(22.0, Double(depth) * 4.5)
        
        // ── 手前カード専用：スライドアニメーション ──
        // 下スクロール（blend 0→1）: slot=0 が下にスライドしながら奥に消える
        //   slideY = blend * frontSlideDown（正 = 下へ）
        // 上スクロール（blend 1→0）: slot=1 が下から上に引き上げられて手前に来る
        //   slot=1 のとき depth = 1 - blend → blend=0 で depth=1（奥）、blend=1 で depth=0（手前）
        //   浮上中のカード（slot=1）は下からせり上がる: slideY = (1 - blend) * frontSlideDown
        
        let slideY: CGFloat = isFrontCard ? blend * frontSlideDown : 0
        
        WayBackCard(
            year: year,
            month: store.referenceMonth,
            day: store.referenceDay,
            isFront: true,
            depthIndex: slot
        )
        .frame(width: W, height: H)
        .scaleEffect(scale, anchor: .bottom)
        .rotation3DEffect(
            .degrees(tiltX),
            axis: (x: 1, y: 0, z: 0),
            anchor: .bottom,
            anchorZ: 0,
            perspective: 0.35
        )
        // shiftY: 奥行き方向（上へ）、slideY: スライド方向（下へ消える / 下から浮上）
        .offset(y: -shiftY + slideY)
        .opacity(opacity)
        .zIndex(Double(store.visibleCardCount - slot))
        .animation(.spring(response: 0.38, dampingFraction: 0.80), value: store.frontYear)
    }
}
