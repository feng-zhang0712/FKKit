import FKUIKit
import UIKit

final class FKIconViewExampleEnvironmentViewController: FKIconViewExampleScrollViewController {

  private let icon: FKIconView = {
    var config = FKIconViewConfiguration()
    config.layout.size = .m
    config.appearance.backgroundStyle = .circle(fill: UIColor.systemTeal.withAlphaComponent(0.15))
    config.appearance.defaultTintColor = .systemTeal
    return FKIconView(configuration: config, symbolName: "arrow.left.arrow.right")
  }()

  private lazy var syncDirectionRow = FKIconViewExampleSupport.settingsRow(title: "Sync direction", icon: icon)
  private let rtlSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & appearance"

    icon.applyDefaultBadgeAnchor()
    icon.fk_badge.showCount(2)

    rtlSwitch.addTarget(self, action: #selector(rtlSwitchChanged), for: .valueChanged)

    let styleControl = UISegmentedControl(items: ["System", "Light", "Dark"])
    styleControl.selectedSegmentIndex = 0
    styleControl.addAction(UIAction { [weak self] action in
      guard let self, let seg = action.sender as? UISegmentedControl else { return }
      switch seg.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let box = FKIconViewExampleSupport.sectionContainer(title: "Layout direction & color")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Background fills and glyph tints adapt to light/dark. Force RTL to verify badge anchor mirroring (top-trailing follows layout direction)."
    ))
    box.addArrangedSubview(syncDirectionRow)
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch, trailing: false))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Interface style", control: styleControl, trailing: false))
    contentStack.addArrangedSubview(box)
  }

  @objc private func rtlSwitchChanged() {
    applyRTL()
  }

  private func applyRTL() {
    let attribute: UISemanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
    FKIconViewExampleSupport.applyLayoutDirection(
      attribute,
      in: self,
      additionally: [syncDirectionRow, icon]
    )
    icon.fk_badge.reattachIfNeeded()
  }
}
