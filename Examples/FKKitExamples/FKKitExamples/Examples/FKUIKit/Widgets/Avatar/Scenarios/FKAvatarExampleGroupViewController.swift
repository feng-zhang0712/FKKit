import FKUIKit
import UIKit

final class FKAvatarExampleGroupViewController: FKAvatarExampleScrollViewController {

  private let group = FKAvatarGroup()
  private let logLabel = FKAvatarExampleSupport.eventLogLabel()
  private let maxVisibleStepper = UIStepper()
  private let overlapSlider = UISlider()
  private let directionControl = UISegmentedControl(items: ["Leading→Trailing", "Trailing→Leading"])
  private let borderSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collaborator stack"

    group.avatars = FKAvatarExampleSupport.sampleGroupMembers()
    group.onAvatarTap = { [weak self] index in
      self?.appendLog("Avatar tapped at index \(index)")
    }
    group.onOverflowTap = { [weak self] in
      self?.appendLog("Overflow +N tapped")
    }

    maxVisibleStepper.minimumValue = 1
    maxVisibleStepper.maximumValue = 6
    maxVisibleStepper.value = 4
    maxVisibleStepper.addAction(UIAction { [weak self] _ in self?.applyGroupConfig() }, for: .valueChanged)

    overlapSlider.minimumValue = -16
    overlapSlider.maximumValue = 0
    overlapSlider.value = -8
    overlapSlider.addAction(UIAction { [weak self] _ in self?.applyGroupConfig() }, for: .valueChanged)

    directionControl.selectedSegmentIndex = 0
    directionControl.addAction(UIAction { [weak self] _ in self?.applyGroupConfig() }, for: .valueChanged)

    borderSwitch.isOn = true
    borderSwitch.addAction(UIAction { [weak self] _ in self?.applyGroupConfig() }, for: .valueChanged)

    let box = FKAvatarExampleSupport.sectionContainer(title: "FKAvatarGroup")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "Overlapping FKAvatar children with +N overflow. White separator border improves contrast between stacked faces."
    ))
    box.addArrangedSubview(FKAvatarExampleSupport.embedGroup(group))
    box.addArrangedSubview(logLabel)
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "maxVisible", control: maxVisibleStepper))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "overlap", control: overlapSlider))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "direction", control: directionControl))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Separator border", control: borderSwitch))

    let reuse = UIButton(type: .system)
    reuse.setTitle("resetForReuse() on all children", for: .normal)
    reuse.addAction(UIAction { [weak self] _ in
      self?.group.resetForReuse()
      self?.appendLog("Called group.resetForReuse()")
    }, for: .touchUpInside)
    box.addArrangedSubview(reuse)

    contentStack.addArrangedSubview(box)
    applyGroupConfig()
  }

  private func applyGroupConfig() {
    var config = FKAvatarGroupConfiguration()
    config.maxVisible = Int(maxVisibleStepper.value)
    config.overlap = CGFloat(overlapSlider.value)
    config.direction = directionControl.selectedSegmentIndex == 0 ? .leadingToTrailing : .trailingToLeading
    config.avatarSize = .s
    config.borderStyle = borderSwitch.isOn
      ? .custom(color: .systemBackground, width: 2)
      : .none
    group.configuration = config
    group.avatars = FKAvatarExampleSupport.sampleGroupMembers()
  }

  private func appendLog(_ line: String) {
    logLabel.text = line + "\n" + (logLabel.text ?? "")
  }
}
