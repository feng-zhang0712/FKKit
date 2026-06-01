import UIKit
import FKUIKit

/// Demonstrates using `FKTabBar` as a bottom-docked bar similar to `UITabBar`.
///
/// Key points:
/// - This is a UIView-level replacement demo only (no TabBarController is provided).
/// - Bottom safe-area behavior is controlled by ``FKTabBarLayoutConfiguration/bottomSafeAreaBehavior``.
/// - Background, divider position, and shadow are configured via `FKTabBarAppearance`.
final class FKTabBarReplaceUITabBarExampleViewController: UIViewController {
  private var configuration = FKTabBarPresets.bottomDocked(showsIndicator: false)
  private var items = FKTabBarExampleSupport.makeItems(5)

  private lazy var tabView: FKTabBar = {
    configuration.layout.preferredBarHeight = 49
    configuration.layout.bottomSafeAreaBehavior = .ignore
    configuration.layout.itemSpacing = 0
    configuration.layout.contentInsets = .zero
    configuration.appearance.backgroundStyle = .solid(.secondarySystemBackground)
    return FKTabBar(items: items, selectedIndex: 0, configuration: configuration)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Replace UITabBar"
    view.backgroundColor = .systemBackground

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)

    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let stack = FKTabBarExampleSupport.makeRootStack(
      in: view,
      topInset: 16,
      scrollBottomAbove: tabView.topAnchor
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Bottom-docked FKTabBar (UIView only)"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Pin FKTabBar to the bottom and toggle bottomSafeAreaBehavior plus background styling. FKTabBar does not provide a TabBarController."))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Non-scrollable fillEqually mode evenly distributes tabs across the bar width. A `_UIScrollViewScrollIndicator` in View Debugger usually means the collection view content is wider than its bounds (often from stale scroll state) — it should not appear once layout is correct."))

    let safeArea = UISegmentedControl(items: ["Ignore", "Pad", "Extend", "Docked"])
    safeArea.selectedSegmentIndex = 0
    safeArea.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      switch safeArea.selectedSegmentIndex {
      case 1: self.configuration.layout.bottomSafeAreaBehavior = .padContent
      case 2: self.configuration.layout.bottomSafeAreaBehavior = .extendBarHeight
      case 3: self.configuration.layout.bottomSafeAreaBehavior = .bottomDocked
      default: self.configuration.layout.bottomSafeAreaBehavior = .ignore
      }
      self.tabView.configuration = self.configuration
      self.tabView.invalidateIntrinsicContentSize()
      self.view.setNeedsLayout()
    }, for: .valueChanged)
    stack.addArrangedSubview(safeArea)

    let itemDirection = UISegmentedControl(items: ["Horizontal", "Vertical"])
    itemDirection.selectedSegmentIndex = 1
    itemDirection.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.itemLayoutDirection = itemDirection.selectedSegmentIndex == 0 ? .horizontal : .vertical
      self.tabView.configuration = self.configuration
      self.tabView.realignSelection(animated: false)
    }, for: .valueChanged)
    stack.addArrangedSubview(itemDirection)

    let surface = UISegmentedControl(items: ["Solid", "Blur"])
    surface.selectedSegmentIndex = 0
    surface.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      if surface.selectedSegmentIndex == 0 {
        self.configuration.appearance.backgroundStyle = .solid(.secondarySystemBackground)
      } else {
        self.configuration.appearance.backgroundStyle = .systemBlur(.systemMaterial)
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(surface)

    let divider = UISegmentedControl(items: ["Divider Top", "Divider Bottom", "No Divider"])
    divider.selectedSegmentIndex = 0
    divider.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      switch divider.selectedSegmentIndex {
      case 1:
        self.configuration.appearance.showsDivider = true
        self.configuration.appearance.dividerPosition = .bottom
      case 2:
        self.configuration.appearance.showsDivider = false
      default:
        self.configuration.appearance.showsDivider = true
        self.configuration.appearance.dividerPosition = .top
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(divider)

    let shadow = UISegmentedControl(items: ["Shadow On", "Shadow Off"])
    shadow.selectedSegmentIndex = 0
    shadow.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      if shadow.selectedSegmentIndex == 0 {
        self.configuration.appearance.shadow = .custom(color: .black, opacity: 0.12, radius: 10, offset: CGSize(width: 0, height: -2))
      } else {
        self.configuration.appearance.shadow = .none
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(shadow)

    let hint = UILabel()
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0
    hint.text = "Tip: run on a device/simulator with Home Indicator to compare ignore vs pad vs extend vs bottomDocked."
    stack.addArrangedSubview(hint)
  }
}
