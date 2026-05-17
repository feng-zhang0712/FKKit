import FKUIKit
import UIKit

/// Base screen with a bound ``FKAudioPlayerView`` and optional event log.
@MainActor
class FKAudioPlayerExampleShellViewController: UIViewController, FKAudioPlayerDelegate {

  let player = FKAudioPlayer()
  let eventLog = FKAudioPlayerExampleEventLog()

  private(set) var playerView: FKAudioPlayerView!
  private let playerContainer = UIView()
  private var logTextView: UITextView?
  private let footerStack = UIStackView()

  /// Inserts a control row above the optional event log.
  func addFooterControls(_ view: UIView) {
    footerStack.insertArrangedSubview(view, at: 0)
  }

  /// When true, a monospace log is shown under the player chrome.
  var showsEventLog = false

  /// Layout style passed to ``FKAudioPlayerView`` (default `.standard`).
  var playerViewStyle: FKAudioPlayerViewStyle = .standard

  /// Height of the player card relative to the safe area (default `0.4`).
  var playerHeightMultiplier: CGFloat = 0.4

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    player.delegate = self

    playerContainer.backgroundColor = .secondarySystemGroupedBackground
    playerContainer.layer.cornerRadius = 12
    playerContainer.clipsToBounds = true
    playerContainer.translatesAutoresizingMaskIntoConstraints = false

    playerView = FKAudioPlayerView(style: playerViewStyle)
    playerView.translatesAutoresizingMaskIntoConstraints = false
    playerContainer.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: playerContainer.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: playerContainer.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: playerContainer.trailingAnchor),
      playerView.bottomAnchor.constraint(equalTo: playerContainer.bottomAnchor),
    ])
    player.bind(to: playerView)

    footerStack.axis = .vertical
    footerStack.spacing = 12
    footerStack.translatesAutoresizingMaskIntoConstraints = false

    if showsEventLog {
      let log = eventLog.makeTextView()
      log.translatesAutoresizingMaskIntoConstraints = false
      log.heightAnchor.constraint(equalToConstant: 140).isActive = true
      logTextView = log
      footerStack.addArrangedSubview(log)
    }

    view.addSubview(playerContainer)
    view.addSubview(footerStack)
  }

  /// Call after `viewDidLoad` once subclasses build their caption or controls.
  func finalizeLayout(topAnchor: NSLayoutYAxisAnchor) {
    NSLayoutConstraint.activate([
      playerContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      playerContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      playerContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      playerContainer.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: playerHeightMultiplier),

      footerStack.topAnchor.constraint(equalTo: playerContainer.bottomAnchor, constant: 12),
      footerStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      footerStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      footerStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  func appendLog(_ message: String) {
    eventLog.append(message)
    if let logTextView {
      eventLog.refresh(logTextView)
    }
  }

  func clearEventLog() {
    eventLog.clear()
    if let logTextView {
      eventLog.refresh(logTextView)
    }
  }

  // MARK: - FKAudioPlayerDelegate

  func audioPlayer(_ player: FKAudioPlayer, didChangeState state: FKMediaPlaybackState) {
    appendLog("state → \(String(describing: state))")
  }

  func audioPlayer(_ player: FKAudioPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval) {
    guard showsEventLog else { return }
    if Int(current) % 5 == 0, abs(current - floor(current)) < 0.25 {
      appendLog(String(format: "time %.1f / %.1f", current, duration))
    }
  }

  func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    appendLog("item → \(item?.title ?? "—") index=\(index.map(String.init) ?? "nil")")
  }

  func audioPlayerDidFinish(_ player: FKAudioPlayer) {
    appendLog("finished")
  }

  func audioPlayer(_ player: FKAudioPlayer, didFail error: FKMediaError) {
    appendLog("failed → \(error.localizedDescription)")
  }

  func audioPlayer(_ player: FKAudioPlayer, didUpdateLyricsLine index: Int?) {
    guard showsEventLog else { return }
    appendLog("lyrics line → \(index.map(String.init) ?? "nil")")
  }

  func audioPlayer(_ player: FKAudioPlayer, didChangeQueueIndex index: Int?) {
    appendLog("queue index → \(index.map(String.init) ?? "nil")")
  }
}
