import AVFoundation
import FKUIKit
import UIKit

/// Renders waveform samples from the active audio asset.
@MainActor
final class FKAudioPlayerWaveformExampleViewController: FKAudioPlayerExampleShellViewController {

  private let waveformView = FKAudioWaveformView()
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    title = "Waveform"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "`FKAudioWaveformView` reads PCM samples from the current `AVAsset` after playback starts."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    waveformView.translatesAutoresizingMaskIntoConstraints = false
    waveformView.backgroundColor = .tertiarySystemGroupedBackground
    waveformView.layer.cornerRadius = 8

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.text = "Waiting for asset…"

    let reload = FKAudioPlayerExampleLayout.makePrimaryButton("Reload waveform", action: UIAction { [weak self] _ in
      Task { await self?.loadWaveform() }
    })
    let stack = UIStackView(arrangedSubviews: [waveformView, statusLabel, reload])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      waveformView.heightAnchor.constraint(equalToConstant: 72),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
    Task { await loadWaveform() }
  }

  private func loadWaveform() async {
    statusLabel.text = "Loading waveform…"
    guard let url = player.currentItem?.source.primaryURL else {
      statusLabel.text = "No URL source on current item."
      return
    }
    let asset = AVURLAsset(url: url)
    await waveformView.loadWaveform(from: asset, sampleCount: 96)
    statusLabel.text = "Waveform ready (\(player.currentItem?.title ?? "—"))"
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    super.audioPlayer(player, didChangeItem: item, index: index)
    Task { await loadWaveform() }
  }
}
