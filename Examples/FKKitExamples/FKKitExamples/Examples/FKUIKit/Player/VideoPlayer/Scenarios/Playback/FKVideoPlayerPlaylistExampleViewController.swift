import FKUIKit
import UIKit

/// Sequential playlist with skip markers and chapter jumps.
@MainActor
final class FKVideoPlayerPlaylistExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Playlist"
    showsEventLog = true
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Episode 3 enables skip intro/outro. Use Next/Previous or wait for auto-advance."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let previous = FKVideoPlayerExampleLayout.makePrimaryButton("Previous", action: UIAction { [weak self] _ in
      self?.player.playPreviousInPlaylist()
    })
    let next = FKVideoPlayerExampleLayout.makePrimaryButton("Next", action: UIAction { [weak self] _ in
      self?.player.playNextInPlaylist()
    })
    let chapters = FKVideoPlayerExampleLayout.makePrimaryButton("Jump to chapter 2", action: UIAction { [weak self] _ in
      guard let chapter = self?.player.currentItem?.chapters.dropFirst().first else { return }
      self?.player.seek(to: chapter.time, completion: nil)
    })

    let row = UIStackView(arrangedSubviews: [previous, next, chapters])
    row.axis = .vertical
    row.spacing = 8
    addFooterControls(row)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(playlist: FKVideoPlayerExampleCatalog.playlist())
    player.play()
  }
}
