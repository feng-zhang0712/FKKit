import FKUIKit
import UIKit

/// Inline plain-text lyrics with optional timestamp lines.
@MainActor
final class FKAudioPlayerPlainLyricsExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Plain lyrics"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Sets `lyricsText` on the item. `FKAudioLyricsParser` extracts `[mm:ss]` markers when present."
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

    player.load(FKAudioPlayerExampleCatalog.itemWithPlainLyrics(), autoPlay: true)
  }
}
