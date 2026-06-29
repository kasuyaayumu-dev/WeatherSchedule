import Foundation
import Network
import Observation

/// 端末のオンライン/オフライン状態を監視する。
@MainActor
@Observable
final class NetworkMonitor {
    private(set) var isOnline = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor.live")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: queue)
    }
    
    /// 起動判定用に、現在の到達性を一度だけ確認する。
    func currentStatus() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor.oneshot")
            var resumed = false
            monitor.pathUpdateHandler = { path in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: path.status == .satisfied)
                monitor.cancel()
            }
            monitor.start(queue: queue)
        }
    }
}
