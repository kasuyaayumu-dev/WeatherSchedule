import SwiftUI

// MARK: - Way Back fullScreenCover
struct WayBackView: View {
    var store: WayBackStore
    var referenceDate: Date?
    
    @State private var twinkle = false
    @State private var showScrollIndicator = true
    @State private var indicatorTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack {
            spaceBackground
            
            VStack(spacing: 0) {
                header
                    .padding(.top, 52)
                
                ZStack(alignment: .bottom) {
                    scrollTrack
                    WayBackCardStack(store: store)
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Color.clear.frame(height: 40)
            }
            
            // スクロールインジケータ
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
    
    // MARK: -
    
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
        }
    }
    
    // MARK: -
    
    private var header: some View {
        HStack(alignment: .center) {
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
            .accessibilityLabel("Way Back")
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
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
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { store.close() }
        }
        .ignoresSafeArea()
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
