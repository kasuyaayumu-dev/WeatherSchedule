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
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .shadow(color: .black.opacity(0.2), radius: 6)
            }
    }
}

// MARK: - カード操作と「同時に」、指の実座標に頂点を一致させるModifier
//
// 【今回の核心修正】
// 以前の実装は rawScrollOffset の差分の符号だけを見て
// 「中央 +80 / -80」に固定的に動かしていたため、実際の指の位置とは無関係だった。
//
// 今回は WayBackView の scrollTrack に追加した simultaneousGesture が
// store.touchLocationY に指の生のY座標（ScrollViewのローカル座標 = 画面座標と一致）
// を書き込んでいるので、それを直接 midPointY に反映する。
// store.touchLocationY が nil になった瞬間（指を離した瞬間）に
// progress を 0 に戻し、中央へ収縮させる。
//
// ジェスチャー自体は持たない（simultaneousGesture は scrollTrack 側にあるため）。
// よってカード操作・×ボタン・ヘッダードラッグと完全に独立して動作する。
struct WayBackSquishyModifier: ViewModifier {
    var store: WayBackStore
    
    @State private var pathProgress: CGFloat = 0
    @State private var midPointY: CGFloat = 0
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let screenWidth = geo.size.width
            
            content
                .onAppear {
                    if midPointY == 0 { midPointY = screenHeight / 2 }
                }
                .onChange(of: store.touchLocationY) { _, newValue in
                    handleTouchChange(newValue, screenHeight: screenHeight)
                }
                .overlay(alignment: .topTrailing) {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: screenWidth, height: screenHeight)
                        .modifier(
                            SquishyAnimatedGlassModifier(
                                progress: pathProgress,
                                midPointY: midPointY,
                                edgeX: screenWidth
                            )
                        )
                        .allowsHitTesting(false)
                }
        }
        .ignoresSafeArea()
    }
    
    private func handleTouchChange(_ newValue: CGFloat?, screenHeight: CGFloat) {
        if let y = newValue {
            // 指が動いている間：伸びた状態を維持しつつ、頂点を指の位置にピタリと合わせる
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.75)) {
                pathProgress = 1.0
                midPointY = y
            }
        } else {
            // 指を離した：スッと中央に戻りながら縮む
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                pathProgress = 0
                midPointY = screenHeight / 2
            }
        }
    }
}

// MARK: - Extension
extension View {
    func wayBackSquishyEffect(store: WayBackStore) -> some View {
        self.modifier(WayBackSquishyModifier(store: store))
    }
}
