import FKUIKit
import UIKit

/// Dark mode, Dynamic Type, and RTL layout overrides.
final class FKSearchExampleEnvironmentViewController: UIViewController {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Environment demo")
  private let searchField = FKSearchField(configuration: FKSearchFieldDefaults.compactFilter(), placeholder: "Compact field")

  private let themeControl = UISegmentedControl(items: ["Auto", "Light", "Dark"])
  private let sizeControl = UISegmentedControl(items: ["Default", "Large", "AX5"])
  private let rtlSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark / Type / RTL"
    view.backgroundColor = .systemGroupedBackground

    themeControl.selectedSegmentIndex = 0
    sizeControl.selectedSegmentIndex = 0

    themeControl.addTarget(self, action: #selector(environmentChanged), for: .valueChanged)
    sizeControl.addTarget(self, action: #selector(environmentChanged), for: .valueChanged)
    rtlSwitch.addTarget(self, action: #selector(environmentChanged), for: .valueChanged)

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Verify semantic colors, growing bar height, and mirrored layout."),
      searchBar,
      searchField,
      labeledRow("Interface style", themeControl),
      labeledRow("Content size", sizeControl),
      labeledRow("Force RTL", rtlSwitch),
    ])

    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])

    environmentChanged()
  }

  @objc private func environmentChanged() {
    switch themeControl.selectedSegmentIndex {
    case 1: overrideUserInterfaceStyle = .light
    case 2: overrideUserInterfaceStyle = .dark
    default: overrideUserInterfaceStyle = .unspecified
    }

    switch sizeControl.selectedSegmentIndex {
    case 1:
      applyLargeContentSize(minimumHeight: 52, fontSize: 20)
    case 2:
      applyLargeContentSize(minimumHeight: 60, fontSize: 28)
    default:
      resetContentSize()
    }

    let direction: UISemanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
    view.semanticContentAttribute = direction
    searchBar.semanticContentAttribute = direction
    searchField.semanticContentAttribute = direction

    [searchBar, searchField].forEach { $0.setNeedsLayout() }
  }

  private func applyLargeContentSize(minimumHeight: CGFloat, fontSize: CGFloat) {
    let font = UIFont.systemFont(ofSize: fontSize)
    searchBar.apply {
      $0.layout.growsWithDynamicType = true
      $0.layout.minimumHeight = minimumHeight
      $0.appearance.textStyle.font = font
    }
    searchField.apply {
      $0.layout.growsWithDynamicType = true
      $0.layout.minimumHeight = minimumHeight
      $0.appearance.textStyle.font = font
    }
  }

  private func resetContentSize() {
    searchBar.apply {
      $0.layout.growsWithDynamicType = true
      $0.layout.minimumHeight = 44
      $0.appearance.textStyle.font = FKSearchTextStyle().font
    }
    searchField.apply {
      $0.layout.growsWithDynamicType = true
      $0.layout.minimumHeight = 44
      $0.appearance.textStyle.font = FKSearchTextStyle().font
    }
  }

  private func labeledRow(_ title: String, _ control: UIView) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }
}
