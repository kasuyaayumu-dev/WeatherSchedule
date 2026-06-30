import SwiftUI

// MARK: - Way Back fullScreenCover
struct WayBackView: View {
    var store: WayBackStore
    var referenceDate: Date?
    
    @State private var twinkle = false
    @State private var showScrollIndicator = true
    @State private var indicatorTask: Task<Void, Never>? = nil
    
    @State private var dismissDragOffset: CGFloat = 0
    @State private var isDismissDragging = false
    
    private let dismissThreshold: CGFloat = 120
    private let maxDragDistance: CGFloat = 260
    private let headerHeight: CGFloat = 52 + 24
    
    var body: some View {
        ZStack {
            spaceBackground
            
            VStack(spacing: 0) {
                header
                
                ZStack(alignment: .bottom) {
                    scrollTrack
                    WayBackCardStack(store: store)
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Color.clear.frame(height: 40)
            }
            
            VStack(spacing: 4) {
                Image(systemName: "chevron.compact.up")
                Text("SCROLL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Image(systemName: "chevron.compact.down")
            }
            .foregroundStyle(.white.opacity(0.45))
            .padding(.trailing, 20)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .allowsHitTesting(false)
            .opacity(showScrollIndicator ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.4), value: showScrollIndicator)
        }
        .offset(y: dismissDragOffset)
        .scaleEffect(dismissScale, anchor: .top)
        .opacity(dismissOpacity)
        .ignoresSafeArea()
        .wayBackSquishyEffect(store: store)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
        .onChange(of: store.frontYear) {
            HapticsManager.wayBackYearChanged()
        }
        .onChange(of: store.rawScrollOffset) {
            if showScrollIndicator {
                showScrollIndicator = false
            }
            indicatorTask?.cancel()
            indicatorTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                showScrollIndicator = true
            }
        }
    }
    
    // MARK: - 閉じる処理（共通化・単一経路）
    
    private func performDismiss(fromDrag: Bool) {
        if fromDrag {
            withAnimation(.easeOut(duration: 0.22)) {
                dismissDragOffset = UIScreen.main.bounds.height
            }
        }
        store.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismissDragOffset = 0
        }
    }
    
    // MARK: - ヘッダードラッグ
    
    private var headerDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                guard value.translation.height > 0 else {
                    dismissDragOffset = 0
                    return
                }
                isDismissDragging = true
                
                let raw = value.translation.height
                if raw <= maxDragDistance {
                    dismissDragOffset = raw
                } else {
                    let overshoot = raw - maxDragDistance
                    dismissDragOffset = maxDragDistance + overshoot * 0.15
                }
            }
            .onEnded { value in
                isDismissDragging = false
                let shouldDismiss = value.translation.height > dismissThreshold
                    || value.predictedEndTranslation.height > dismissThreshold * 1.5
                
                if shouldDismiss {
                    performDismiss(fromDrag: true)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        dismissDragOffset = 0
                    }
                }
            }
    }
    
    private var dismissScale: CGFloat {
        guard dismissDragOffset > 0 else { return 1.0 }
        let progress = min(dismissDragOffset / maxDragDistance, 1.0)
        return 1.0 - progress * 0.06
    }
    
    private var dismissOpacity: CGFloat {
        guard dismissDragOffset > 0 else { return 1.0 }
        let progress = min(dismissDragOffset / (maxDragDistance * 1.3), 1.0)
        return 1.0 - progress * 0.35
    }
    
    // MARK: - scrollTrack
    //
    // 【今回の追加】
    // .simultaneousGesture(DragGesture()) を追加。
    // simultaneousGesture は ScrollView 本体の組み込みジェスチャーと
    // "同時に・対等に" 動作し、どちらか一方がもう一方を妨げない。
    // ここで拾った value.location（ScrollView のローカル座標）を
    // store.touchLocationY に書き込み、SquishyEdgeEffect 側が
    // それを直接読んでエフェクトの頂点Y座標に反映する。
    // ドラッグ終了時は nil に戻し、エフェクト側が中央に戻る合図にする。
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
            .scrollTargetBehavior(CardSnapBehavior(pageHeight: store.cardScrollHeight))
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                store.rawScrollOffset = max(0, offset)
            }
            .scrollDisabled(isDismissDragging)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        // ★重要: ここの座標は scrollTrack 自身のローカル座標（上端=0）。
                        // SquishyEdgeEffect 側は WayBackView 全体（ヘッダー含む）を
                        // 基準にした GeometryReader を使っているため、
                        // headerHeight 分のオフセットを足して座標系を揃える。
                        store.touchLocationY = value.location.y + headerHeight
                    }
                    .onEnded { _ in
                        store.touchLocationY = nil
                    }
            )
        }
    }
    
    // MARK: - ヘッダー
    
    private var header: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(headerDismissGesture)
            
            HStack(alignment: .center) {
                Label("Way Back", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .allowsHitTesting(false)
                
                Spacer()
                    .allowsHitTesting(false)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.35))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            performDismiss(fromDrag: false)
                        }
                    )
                    .accessibilityLabel("Way Back を閉じる")
                    .accessibilityAddTraits(.isButton)
            }
            .padding(.horizontal, 22)
        }
        .frame(height: headerHeight)
        .padding(.top, 52 - 24)
    }
    
    // MARK: -
    
    private var spaceBackground: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.00, green: 0.00, blue: 0.06), location: 0.00),
                    .init(color: Color(red: 0.03, green: 0.01, blue: 0.16), location: 0.30),
                    .init(color: Color(red: 0.08, green: 0.02, blue: 0.24), location: 0.60),
                    .init(color: Color(red: 0.01, green: 0.01, blue: 0.10), location: 1.00)
                ],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(red: 0.28, green: 0.08, blue: 0.58).opacity(0.40), .clear],
                center: .init(x: 0.78, y: 0.22), startRadius: 10, endRadius: 300
            )
            RadialGradient(
                colors: [Color(red: 0.08, green: 0.18, blue: 0.55).opacity(0.28), .clear],
                center: .init(x: 0.18, y: 0.72), startRadius: 10, endRadius: 240
            )
            
            Canvas { context, size in
                var rng = SeededRandom(seed: 42)
                for i in 0..<80 {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height
                    let r = rng.next() * 1.6 + 0.3
                    let base = Double(rng.next()) * 0.65 + 0.08
                    let op = twinkle ? (i % 3 == 0 ? base * 0.25 : base) : base
                    context.fill(
                        Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                        with: .color(.white.opacity(op))
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - fullScreenCover Modifier
extension View {
    func wayBackFullScreen(store: WayBackStore, referenceDate: Date? = nil) -> some View {
        let binding = Binding<Bool>(
            get: { store.isPresented },
            set: { newVal in
                if !newVal { store.close() }
            }
        )
        return self.fullScreenCover(isPresented: binding) {
            WayBackView(store: store, referenceDate: referenceDate)
        }
    }
}

// MARK: - CardSnapBehavior iOS 17+
struct CardSnapBehavior: ScrollTargetBehavior {
    let pageHeight: CGFloat
    
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let page = (target.rect.minY / pageHeight).rounded()
        target.rect.origin.y = page * pageHeight
    }
}

// MARK: - PreferenceKey
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: -
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat(state >> 33) / CGFloat(0x7FFF_FFFF)
    }
}
