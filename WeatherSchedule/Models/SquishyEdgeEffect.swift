import SwiftUI

// MARK: - ぐにゃんとなる形状を描画するモディファイア
struct SquishyAnimatedGlassModifier: AnimatableModifier {
    var progress: CGFloat
    var midPointY: CGFloat
    let edgeX: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, midPointY) }
        set {
            progress = newValue.first
            midPointY = newValue.second
        }
    }
    
    var path: Path {
        Path { path in
            let mountainHeight: CGFloat = 300
            let startY = midPointY - (mountainHeight / 2) * progress
            let endY = midPointY + (mountainHeight / 2) * progress
            
            let direction: CGFloat = (edgeX == 0) ? 1 : -1
            let peakX = edgeX + (45 * progress) * direction
            let midPoint = CGPoint(x: peakX, y: midPointY)
            
            let cp1 = CGPoint(x: edgeX, y: startY + (midPointY - startY) / 2)
            let cp2 = CGPoint(x: midPoint.x, y: midPointY - 70 * progress)
            let cp3 = CGPoint(x: midPoint.x, y: midPointY + 70 * progress)
            let cp4 = CGPoint(x: edgeX, y: midPointY + (endY - midPointY) / 2)
            
            path.move(to: CGPoint(x: edgeX, y: startY))
            path.addCurve(to: midPoint, control1: cp1, control2: cp2)
            path.addCurve(to: CGPoint(x: edgeX, y: endY), control1: cp3, control2: cp4)
        }
    }
    
    func body(content: Content) -> some View {
        content.mask(path)
            .background {
                path
                    .fill(.ultraThinMaterial) // ウェイバックの宇宙背景に馴染むすりガラス効果
                    .environment(\.colorScheme, .dark)
                    .shadow(color: .black.opacity(0.2), radius: 6)
            }
    }
}

// MARK: - 画面操作を一切邪魔しない専用Modifier
struct WayBackSquishyModifier: ViewModifier {
    var store: WayBackStore
    
    @State private var pathProgress: CGFloat = 0
    @State private var midPointY: CGFloat = UIScreen.main.bounds.height / 2
    @State private var resetTask: Task<Void, Never>? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            // 1. 元のコンテンツ（ジェスチャーは追加しないので完全に安全！）
            content
                // ⚠️ ここを `store.rawScrollOffset` に修正しました！
                .onChange(of: store.rawScrollOffset) { oldValue, newValue in
                    // スクロールが発生したら即座に一定の幅で伸ばす
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7)) {
                        pathProgress = 1.0
                    }
                    
                    // 指の位置の代わりに、スクロール方向（上か下か）に合わせて中心点を上下に動かす
                    let isScrollingDown = newValue > oldValue
                    let targetY = UIScreen.main.bounds.height / 2 + (isScrollingDown ? 80 : -80)
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                        midPointY = targetY
                    }
                    
                    // スクロールが止まったら（0.15秒後に）滑らかに戻す
                    resetTask?.cancel()
                    resetTask = Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        if !Task.isCancelled {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                pathProgress = 0
                                midPointY = UIScreen.main.bounds.height / 2 // 中心に戻す
                            }
                        }
                    }
                }
            
            // 2. エフェクト描画レイヤー
            GeometryReader { geometry in
                let w = geometry.size.width
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .modifier(
                            SquishyAnimatedGlassModifier(
                                progress: pathProgress,
                                midPointY: midPointY,
                                edgeX: w
                            )
                        )
                }
                .allowsHitTesting(false) // タッチイベントを完全に貫通させる
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Extension
extension View {
    func wayBackSquishyEffect(store: WayBackStore) -> some View {
        self.modifier(WayBackSquishyModifier(store: store))
    }
}
