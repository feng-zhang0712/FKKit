import FKUIKit
import UIKit

/// Loads bundled LRC lyrics into ``FKAudioLyricsView``.
@MainActor
final class FKAudioPlayerLRCLyricsExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Bundled LRC"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Loads bundled `sample.lrc`. Scroll the lyrics panel inside the player chrome while audio plays."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    playerHeightMultiplier = 0.52
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.itemWithBundledLRC(), autoPlay: true)
  }
}
