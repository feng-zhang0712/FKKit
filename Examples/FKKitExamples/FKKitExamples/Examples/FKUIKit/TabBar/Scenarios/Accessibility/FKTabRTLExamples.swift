import UIKit
import FKUIKit

/// Demonstrates RTL behavior and layout direction for `FKTabBar` in scrollable mode.
///
/// Verification checklist:
/// - Toggle RTL and ensure the visual order mirrors correctly.
/// - In scrollable mode, selecting different indices should keep the selected item visible and aligned.
/// - The indicator should move in the expected direction with selection changes (no "backwards" jumps).
///
/// FKTabBar boundaries:
/// - FKTabBar is UI-only. It does not manage any controller/pager; hosts decide selection and progress inputs.
final class FKTabBarRTLExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(layout: .init(isScrollable: true, widthMode: .intrinsic))
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(11), selectedIndex: 0, configuration: configuration)

  private let rtlSwitch = UISegmentedControl(items: ["System", "Force LTR", "Force RTL"])
  private let semanticSwitch = UISegmentedControl(items: ["Semantic: Default", "Semantic: RTL"])
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL"
    view.backgroundColor = .systemBackground

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 56)

    let stack = FKTabBarExampleSupport.makeRootStack(
      in: view,
      scrollTopBelow: tabView.bottomAnchor,
      scrollTopSpacing: 16
    )
    view.bringSubviewToFront(tabView)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("RTL + layout direction"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Validate rtlBehavior, semantic RTL, itemLayoutDirection (horizontal/vertical), selection auto-scroll, and indicator movement."))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("To validate system RTL: Settings → General → Language & Region (or Xcode scheme Application Language)."))

    semanticSwitch.selectedSegmentIndex = 0
    semanticSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let forceRTL = self.semanticSwitch.selectedSegmentIndex == 1
      self.view.semanticContentAttribute = forceRTL ? .forceRightToLeft : .unspecified
      self.tabView.semanticContentAttribute = forceRTL ? .forceRightToLeft : .unspecified
      self.appendStatus("semanticContentAttribute: \(forceRTL ? "force RTL" : "default")")
    }, for: .valueChanged)
    stack.addArrangedSubview(semanticSwitch)

    rtlSwitch.selectedSegmentIndex = 0
    rtlSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      switch self.rtlSwitch.selectedSegmentIndex {
      case 1: self.configuration.layout.rtlBehavior = .forceLeftToRight
      case 2: self.configuration.layout.rtlBehavior = .forceRightToLeft
      default: self.configuration.layout.rtlBehavior = .automatic
      }
      self.tabView.configuration = self.configuration
      self.appendStatus("layout.rtlBehavior: \(self.configuration.layout.rtlBehavior)")
    }, for: .valueChanged)
    stack.addArrangedSubview(rtlSwitch)

    let layoutDirection = UISegmentedControl(items: ["Leading+Text", "Top+Bottom"])
    layoutDirection.selectedSegmentIndex = 0
    layoutDirection.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.itemLayoutDirection = layoutDirection.selectedSegmentIndex == 0 ? .horizontal : .vertical
      self.tabView.applyConfiguration(self.configuration, animated: false)
      self.appendStatus("itemLayoutDirection: \(self.configuration.layout.itemLayoutDirection)")
    }, for: .valueChanged)
    stack.addArrangedSubview(layoutDirection)

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select first") { [weak self] in
      self?.tabView.setSelectedIndex(0, animated: true, reason: .programmatic)
    })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select last") { [weak self] in
      self?.tabView.setSelectedIndex(10, animated: true, reason: .programmatic)
    })
    stack.addArrangedSubview(actions)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Ready."
    stack.addArrangedSubview(statusLabel)

    tabView.onSelectionChanged = { [weak self] item, index, _ in
      self?.appendStatus("selected: \(index) (\(item.titleText ?? item.id))")
    }
  }

  private func appendStatus(_ line: String) {
    statusLabel.text = line
  }
}

