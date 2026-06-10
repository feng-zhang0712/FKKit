import FKUIKit
import UIKit

final class FKAvatarExampleEnvironmentViewController: FKAvatarExampleScrollViewController {

  private let avatar = FKAvatar()
  private let group = FKAvatarGroup()
  private let rtlSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & appearance"

    var avatarConfig = FKAvatarConfiguration()
    avatarConfig.layout.size = .l
    avatarConfig.showsPresenceIndicator = true
    avatarConfig.presenceState = .online
    avatarConfig.appearance.showsVerifiedBadge = true
    avatar.configuration = avatarConfig
    avatar.displayName = "Alex Morgan"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 64, size: 160), placeholder: nil)

    var groupConfig = FKAvatarGroupConfiguration()
    groupConfig.borderStyle = .custom(color: .systemBackground, width: 2)
    group.configuration = groupConfig
    group.avatars = Array(FKAvatarExampleSupport.sampleGroupMembers().prefix(5))

    rtlSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let forceRTL = self.rtlSwitch.isOn
      let attribute: UISemanticContentAttribute = forceRTL ? .forceRightToLeft : .unspecified
      self.view.semanticContentAttribute = attribute
      self.avatar.semanticContentAttribute = attribute
      self.group.semanticContentAttribute = attribute
    }, for: .valueChanged)

    let style = UISegmentedControl(items: ["System", "Light", "Dark"])
    style.selectedSegmentIndex = 0
    style.addAction(UIAction { [weak self] action in
      guard let self, let seg = action.sender as? UISegmentedControl else { return }
      switch seg.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let box = FKAvatarExampleSupport.sectionContainer(title: "Layout direction & color")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "Presence indicator, verified badge, and FKAvatarGroup stack mirror under forced RTL. Toggle light/dark to inspect border and overflow chip contrast."
    ))
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    box.addArrangedSubview(FKAvatarExampleSupport.embedGroup(group))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Interface style", control: style))

    contentStack.addArrangedSubview(box)
  }
}
