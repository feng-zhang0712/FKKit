import FKUIKit
import UIKit

/// Demonstrates ``FKAudioMiniBar`` docked above the safe area.
@MainActor
final class FKAudioPlayerMiniBarExampleViewController: FKAudioPlayerExampleShellViewController {

  private let miniBar = FKAudioMiniBar()

  override func viewDidLoad() {
    title = "Mini bar"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Standard player chrome above; tap the mini bar to open the Now Playing page."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    miniBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(miniBar)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      miniBar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      miniBar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      miniBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.bind(miniBar: miniBar)
    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }

  override func audioPlayer(
    _ player: FKAudioPlayer,
    didUpdateTime current: TimeInterval,
    duration: TimeInterval
  ) {
    super.audioPlayer(player, didUpdateTime: current, duration: duration)
    miniBar.updateProgress(current: current, duration: duration)
  }
}
