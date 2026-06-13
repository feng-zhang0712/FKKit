import FKUIKit
import UIKit

final class FKAvatarExamplePresenceIndicatorViewController: FKAvatarExampleScrollViewController {

  private let preview = FKPresenceIndicator()
  private let sizeControl = UISegmentedControl(items: ["S (8pt)", "M (10pt)", "L (12pt)"])
  private let pulseSwitch = UISwitch()
  private let borderSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presence states"

    sizeControl.selectedSegmentIndex = 1
    pulseSwitch.isOn = true
    borderSwitch.isOn = true
    preview.state = .online

    [sizeControl, pulseSwitch, borderSwitch].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfig() }, for: .valueChanged)
    }

    let box = FKAvatarExampleSupport.sectionContainer(title: "Standalone indicator")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "FKPresenceIndicator covers online, offline, busy, away, and custom states. Online pulse respects Reduce Motion."
    ))

    let previewRow = UIStackView()
    previewRow.axis = .vertical
    previewRow.alignment = .center
    preview.translatesAutoresizingMaskIntoConstraints = false
    previewRow.addArrangedSubview(preview)
    box.addArrangedSubview(previewRow)

    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Size", control: sizeControl))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Pulse when online", control: pulseSwitch))
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Border", control: borderSwitch))

    let stateRow = FKAvatarExampleSupport.horizontalRow(spacing: 8)
    stateRow.distribution = .fillEqually
    [
      ("Online", FKPresenceState.online),
      ("Away", FKPresenceState.away),
      ("Busy", FKPresenceState.busy),
      ("Offline", FKPresenceState.offline),
    ].forEach { title, state in
      let button = UIButton(type: .system)
      button.setTitle(title, for: .normal)
      button.addAction(UIAction { [weak self] _ in
        self?.preview.state = state
      }, for: .touchUpInside)
      stateRow.addArrangedSubview(button)
    }
    box.addArrangedSubview(stateRow)

    let custom = UIButton(type: .system)
    custom.setTitle("Custom state (purple, pulse)", for: .normal)
    custom.addAction(UIAction { [weak self] _ in
      self?.preview.state = .custom(FKPresenceCustomState(
        identifier: "streaming",
        color: .systemPurple,
        accessibilityLabel: "Streaming",
        pulses: true
      ))
    }, for: .touchUpInside)
    box.addArrangedSubview(custom)

    contentStack.addArrangedSubview(box)
    buildEmbeddedSample()
    applyConfig()
  }

  private func buildEmbeddedSample() {
    var config = FKAvatarConfiguration()
    config.layout.size = .m
    config.showsPresenceIndicator = true
    config.presenceState = .busy
    let avatar = FKAvatar(configuration: config)
    avatar.displayName = "Embedded on avatar"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 69, size: 120), placeholder: nil)

    let box = FKAvatarExampleSupport.sectionContainer(title: "Embedded (merged VoiceOver)")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "When attached to FKAvatar, presence is merged into the avatar accessibility hint — not separately focusable."
    ))
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    contentStack.addArrangedSubview(box)
  }

  private func applyConfig() {
    let size: FKPresenceIndicatorSize
    switch sizeControl.selectedSegmentIndex {
    case 0: size = .s
    case 2: size = .l
    default: size = .m
    }
    preview.configuration = FKPresenceIndicatorConfiguration(
      size: size,
      showsBorder: borderSwitch.isOn,
      pulsesWhenOnline: pulseSwitch.isOn
    )
  }
}
