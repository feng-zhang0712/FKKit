import FKUIKit
import UIKit

final class FKAvatarExampleRemoteURLViewController: FKAvatarExampleScrollViewController {

  private let avatar = FKAvatar()
  private let stateLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Remote URL"

    var config = FKAvatarConfiguration()
    config.layout.size = .xl
    config.appearance.prefersSkeletonLoadingIndicator = true
    avatar.configuration = config
    avatar.displayName = "Remote user"

    stateLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
    stateLabel.textColor = .label
    stateLabel.numberOfLines = 0
    stateLabel.text = "Tap Reload to fetch a remote avatar."

    let box = FKAvatarExampleSupport.sectionContainer(title: "HTTPS avatar")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "URL loading uses the embedded FKImageView + FKImageLoader. Skeleton shimmer appears while loading."
    ))
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    box.addArrangedSubview(stateLabel)

    let reload = UIButton(type: .system)
    reload.setTitle("Reload URL", for: .normal)
    reload.addAction(UIAction { [weak self] _ in
      self?.loadSample()
    }, for: .touchUpInside)
    box.addArrangedSubview(reload)

    contentStack.addArrangedSubview(box)
    loadSample()
  }

  private func loadSample() {
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 66, size: 240), placeholder: nil)
    stateLabel.text = "Loading https://picsum.photos/… (skeleton → image fade-in)."
  }
}
