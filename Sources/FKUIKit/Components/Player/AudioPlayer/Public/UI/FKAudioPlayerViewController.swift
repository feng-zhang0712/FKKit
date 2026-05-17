import UIKit

/// Full-screen "Now Playing" page for ``FKAudioPlayer``.
@MainActor
public final class FKAudioPlayerViewController: UIViewController {

  public let player: FKAudioPlayer
  private let playerView: FKAudioPlayerView

  public init(player: FKAudioPlayer, style: FKAudioPlayerViewStyle = .standard) {
    self.player = player
    self.playerView = FKAudioPlayerView(style: style)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(closeTapped)
    )

    playerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      playerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
    playerView.bind(player: player)
    player.attachChrome(playerView)
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isBeingDismissed, let boundView = player.boundView {
      player.syncChrome(with: boundView)
    }
  }

  @objc
  private func closeTapped() {
    dismiss(animated: true)
  }
}
