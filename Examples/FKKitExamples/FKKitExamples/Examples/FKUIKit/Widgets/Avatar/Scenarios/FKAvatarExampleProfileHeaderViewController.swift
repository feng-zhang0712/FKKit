import FKUIKit
import UIKit

final class FKAvatarExampleProfileHeaderViewController: FKAvatarExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Profile header"

    contentStack.addArrangedSubview(FKAvatarExampleSupport.caption(
      "Large avatar with optional story gradient ring, border stroke, and verified badge overlay."
    ))

    var config = FKAvatarConfiguration()
    config.layout.size = .xl
    config.appearance.borderStyle = .custom(color: .white, width: 3)
    config.appearance.storyRing = FKAvatarStoryRingConfiguration(
      width: 3,
      gradientColors: [.systemPink, .systemOrange, .systemPurple],
      padding: 3
    )
    config.appearance.showsVerifiedBadge = true
    config.showsPresenceIndicator = true
    config.presenceState = .online

    let avatar = FKAvatar(configuration: config)
    avatar.displayName = "Alex Morgan"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 64, size: 320), placeholder: nil)

    let box = FKAvatarExampleSupport.sectionContainer(title: "XL · story · border · verified · presence")
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    contentStack.addArrangedSubview(box)

    buildCompactVariant()
  }

  private func buildCompactVariant() {
    var config = FKAvatarConfiguration()
    config.layout.size = .l
    config.appearance.borderStyle = .custom(color: .separator, width: 2)
    config.showsPresenceIndicator = true
    config.presenceState = .away

    let avatar = FKAvatar(configuration: config)
    avatar.displayName = "Section header size L"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 65, size: 160), placeholder: nil)

    let box = FKAvatarExampleSupport.sectionContainer(title: "Size L · border · presence")
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    contentStack.addArrangedSubview(box)
  }
}
