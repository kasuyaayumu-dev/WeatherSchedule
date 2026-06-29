import SwiftUI

/// 起動フローの入口。AppDataManager の状態に応じて画面を切り替える。
struct ContentView: View {
    @State private var manager = AppDataManager()
    
    var body: some View {
        Group {
            switch manager.launchState {
            case .launching:
                LaunchingView()
            case .ready:
                CalendarView(store: manager.calendarStore)
            case .stopped(let message):
                StopAppView(message: message) {
                    Task { await manager.retry() }
                }
            }
        }
        .task { await manager.start() }
    }
}

/// 起動判定中のスプラッシュ。
private struct LaunchingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 56))
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
