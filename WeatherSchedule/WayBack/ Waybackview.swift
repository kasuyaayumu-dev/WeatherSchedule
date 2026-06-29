import SwiftUI

// MARK: - Way Back オーバーレイ（没入感重視・年バッジなし）

struct WayBackView: View {
    var store: WayBackStore
    var referenceDate: Date?
    
    @State private var twinkle = false
    
    var body: some View {
        ZStack {
            spaceBackground
            
            VStack(spacing: 0) {
                // ヘッダー（薄く・小さく）
                header
                    .padding(.top, 52)
                
                // カードスタック ＋ 透明スクロールトラック
                ZStack(alignment: .bottom) {
                    scrollTrack
                    WayBackCardStack(store: store)
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Color.clear.frame(height: 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
    }
    
    // MARK: - 透明スクロールトラック
    
    private var scrollTrack: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                Color.clear
                    .frame(height: geo.size.height + store.totalScrollHeight)
                    .background(
                        GeometryReader { inner in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: -inner.frame(in: .named("waybackScroll")).minY
                            )
                        }
                    )
            }
            .coordinateSpace(name: "waybackScroll")
            .defaultScrollAnchor(.bottom)
            // iOS 17対応スナップ: cardScrollHeight ピッチでページング
            .scrollTargetBehavior(CardSnapBehavior(pageHeight: store.cardScrollHeight))
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                store.rawScrollOffset = max(0, offset)
            }
        }
    }
    
    // MARK: - ヘッダー（ミニマル化）
    
    private var header: some View {
        HStack(alignment: .center) {
            // ラベルは小さく・透明感を上げる
            Label("Way Back", systemImage: "clock.arrow.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
            
            Spacer()
            
            Button(action: { store.close() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.35))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Way Backを閉じる")
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }
    
    // MARK: - 宇宙背景
    
    private var spaceBackground: some View {
        ZStack {
            // ベースグラデーション
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.00, green: 0.00, blue: 0.06), location: 0.00),
                    .init(color: Color(red: 0.03, green: 0.01, blue: 0.16), location: 0.30),
                    .init(color: Color(red: 0.08, green: 0.02, blue: 0.24), location: 0.60),
                    .init(color: Color(red: 0.01, green: 0.01, blue: 0.10), location: 1.00)
                ],
                startPoint: .top, endPoint: .bottom
            )
            // 星雲
            RadialGradient(
                colors: [Color(red: 0.28, green: 0.08, blue: 0.58).opacity(0.40), .clear],
                center: .init(x: 0.78, y: 0.22), startRadius: 10, endRadius: 300
            )
            RadialGradient(
                colors: [Color(red: 0.08, green: 0.18, blue: 0.55).opacity(0.28), .clear],
                center: .init(x: 0.18, y: 0.72), startRadius: 10, endRadius: 240
            )
            // 星フィールド
            Canvas { context, size in
                var rng = SeededRandom(seed: 42)
                for i in 0..<80 {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height
                    let r = rng.next() * 1.6 + 0.3
                    let base = Double(rng.next()) * 0.65 + 0.08
                    // 3フレーム毎に瞬く
                    let op = twinkle ? (i % 3 == 0 ? base * 0.25 : base) : base
                    context.fill(
                        Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                        with: .color(.white.opacity(op))
                    )
                }
            }
            .allowsHitTesting(false)
            
            // 閉じるタップ領域（カードより背面）
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { store.close() }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 年スクラバー

// MARK: - Modifier

extension View {
//    func wayBackOverlay(store: WayBackStore, referenceDate: Date? = nil) -> some View {
//        self.overlay {
//            if store.isPresented {
//                WayBackView(store: store, referenceDate: referenceDate)
//                    .transition(.asymmetric(
//                        insertion: .opacity.combined(with: .move(edge: .bottom)),
//                        removal:   .opacity.combined(with: .scale(scale: 0.96, anchor: .center))
//                    ))
//            }
//        }
//        .animation(.spring(response: 0.44, dampingFraction: 0.84), value: store.isPresented)
//    }
    func wayBackFullScreen(store: WayBackStore, referenceDate: Date? = nil) -> some View {
        // Bindable を使って @Observable の isPresented を Binding に変換
        self.fullScreenCover(isPresented: Bindable(store).isPresented) {
          WayBackView(store: store, referenceDate: referenceDate)
        }
      }
}

// MARK: - iOS 17 カスタムスナップ

/// 指を離したとき pageHeight の倍数に最も近い位置へスナップする。
struct CardSnapBehavior: ScrollTargetBehavior {
    let pageHeight: CGFloat
    
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let offset = target.rect.minY
        // 最寄りのページ境界を計算
        let page = (offset / pageHeight).rounded()
        let snapped = page * pageHeight
        target.rect.origin.y = snapped
    }
}

// MARK: - 決定論的疑似乱数

private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat(state >> 33) / CGFloat(0x7FFF_FFFF)
    }
}
