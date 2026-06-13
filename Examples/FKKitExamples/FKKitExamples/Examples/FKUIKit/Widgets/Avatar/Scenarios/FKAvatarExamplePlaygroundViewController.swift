import FKUIKit
import UIKit

final class FKAvatarExamplePlaygroundViewController: FKAvatarExampleScrollViewController {

  private let avatar = FKAvatar()
  private let sizeControl = UISegmentedControl(items: ["XS", "S", "M", "L", "XL"])
  private let shapeControl = UISegmentedControl(items: ["Circle", "Squircle", "Rounded"])
  private let storySwitch = UISwitch()
  private let presenceSwitch = UISwitch()
  private let verifiedSwitch = UISwitch()
  private let highlightSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"

    avatar.displayName = "Playground"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 68, size: 200), placeholder: nil)

    sizeControl.selectedSegmentIndex = 2
    shapeControl.selectedSegmentIndex = 0
    storySwitch.isOn = false
    presenceSwitch.isOn = false
    verifiedSwitch.isOn = false
    highlightSwitch.isOn = true

    [sizeControl, shapeControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }
    [storySwitch, presenceSwitch, verifiedSwitch, highlightSwitch].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }

    let box = FKAvatarExampleSupport.sectionContainer(title: "Live preview")
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Size", control: sizeControl))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Shape", control: shapeControl))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Story ring", control: storySwitch))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Presence", control: presenceSwitch))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Verified badge", control: verifiedSwitch))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Highlight on press", control: highlightSwitch))

    contentStack.addArrangedSubview(box)
    applyConfiguration()
  }

  private func applyConfiguration() {
    var config = FKAvatarConfiguration()
    config.layout.size = resolvedSize()
    config.layout.shape = resolvedShape()
    config.appearance.storyRing = storySwitch.isOn
      ? FKAvatarStoryRingConfiguration()
      : nil
    config.appearance.showsVerifiedBadge = verifiedSwitch.isOn
    config.appearance.borderStyle = storySwitch.isOn
      ? .custom(color: .white, width: 2)
      : .none
    config.showsPresenceIndicator = presenceSwitch.isOn
    config.presenceState = presenceSwitch.isOn ? .online : nil
    config.interaction.highlightsOnPress = highlightSwitch.isOn
    avatar.configuration = config
  }

  private func resolvedSize() -> FKAvatarSize {
    switch sizeControl.selectedSegmentIndex {
    case 0: .xs
    case 1: .s
    case 3: .l
    case 4: .xl
    default: .m
    }
  }

  private func resolvedShape() -> FKAvatarShape {
    switch shapeControl.selectedSegmentIndex {
    case 1: .squircle(cornerRadius: 12)
    case 2: .roundedRectangle(cornerRadius: 8)
    default: .circle
    }
  }
}
