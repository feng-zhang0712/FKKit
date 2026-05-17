import FKUIKit
import SwiftUI
import UIKit

/// Hosts ``FKAudioPlayerSwiftUIView`` inside a UIKit shell.
@MainActor
final class FKAudioPlayerSwiftUIExampleViewController: UIViewController {

  private let player = FKAudioPlayer()

  override func viewDidLoad() {
    title = "SwiftUI bridge"
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "SwiftUI representable binds the same `FKAudioPlayer` instance as UIKit screens."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let hosting = UIHostingController(
      rootView: FKAudioPlayerSwiftUIView(player: player, style: .standard)
    )
    addChild(hosting)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hosting.view)
    hosting.didMove(toParent: self)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      hosting.view.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 12),
      hosting.view.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }
}
