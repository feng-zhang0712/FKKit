import FKUIKit
import UIKit

/// Presents ``FKAudioPlayerViewController`` as a modal Now Playing page.
@MainActor
final class FKAudioPlayerNowPlayingExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Now Playing"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Opens the full-screen host that embeds `FKAudioPlayerView` and reuses the same player instance."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let open = FKAudioPlayerExampleLayout.makePrimaryButton("Present Now Playing", action: UIAction { [weak self] _ in
      guard let self else { return }
      let controller = FKAudioPlayerViewController(player: self.player)
      controller.modalPresentationStyle = .fullScreen
      self.present(controller, animated: true)
    })
    addFooterControls(open)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackTwo(), autoPlay: true)
  }
}
