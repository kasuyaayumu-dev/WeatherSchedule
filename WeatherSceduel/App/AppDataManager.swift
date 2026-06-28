import Foundation
import Observation

/// 起動フロー（オフラインファースト）とアプリ全体のデータを統括する。
/// フローチャート（オンライン/オフライン × 保存データ有無）の分岐をここに集約する。
@MainActor
@Observable
final class AppDataManager {
  enum LaunchState: Equatable {
    case launching
    case ready
    case stopped(message: String)
  }

  private(set) var launchState: LaunchState = .launching

  let network = NetworkMonitor()
  let cache = ForecastCache()
  let calendarStore: CalendarStore

  init() {
    calendarStore = CalendarStore(cache: cache, network: network)
  }

  /// フローチャートに沿った起動処理。
  func start() async {
    launchState = .launching
    let online = await network.currentStatus()

    if online {
      if cache.hasSavedData {
        // 保存済みデータあり → 変更有無を確認
        if await hasRemoteChanges() {
          await refreshFromAPI()
        }
        // 変更なし → ローカルデータのまま起動
      } else {
        // 保存済みデータなし → API から取得・保存して起動
        await refreshFromAPI()
      }
      cache.prune() // 設定範囲外を整理
      calendarStore.reloadFromCache()
      launchState = .ready
    } else {
      if cache.hasSavedData {
        // オフライン + 保存データあり → ローカルで起動
        calendarStore.reloadFromCache()
        launchState = .ready
      } else {
        // オフライン + 保存データなし → 進行を止める
        launchState = .stopped(message: "追加ダウンロードがあります。\nネット環境を確認してください。")
      }
    }
  }

  func retry() async { await start() }

  // MARK: - スタブ（差分API・一括取得は後続フェーズで実装）

  /// サーバー側に変更があるか。将来は更新日時/ETag で判定する。
  private func hasRemoteChanges() async -> Bool {
    false
  }

  /// API から予測データを取得して保存する。
  /// 設定値（保存年数・月数）で取得範囲を制限できるよう引数を用意したスタブ。
  /// 現状は起動をブロックせず、個々の日付は表示時に CalendarStore が遅延取得する。
  private func refreshFromAPI(pastYears: Int = CacheSettings.pastYears,
                             futureMonths: Int = CacheSettings.futureMonths) async {
    // TODO: 指定範囲分の予報をまとめて取得し cache.store(...) で保存する。
  }
}
