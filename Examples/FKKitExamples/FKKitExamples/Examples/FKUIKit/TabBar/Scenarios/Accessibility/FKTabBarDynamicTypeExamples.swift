import UIKit
import FKUIKit

/// Demonstrates Dynamic Type adaptation strategies for `FKTabBar`.
///
/// How to test:
/// - Settings → Accessibility → Display & Text Size → Larger Text
/// - Increase to an accessibility category and observe label layout and bar height.
///
/// Key points:
/// - `largeTextLayoutStrategy` controls behavior in accessibility categories.
/// - FKTabBar is UI-only: it adapts to trait changes but does not manage any controller/pager.
final class FKTabBarDynamicTypeExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(
    layout: FKTabBarLayoutConfiguration(
      isScrollable: true,
      itemSpacing: 10,
      contentInsets: .init(top: 0, leading: 16, bottom: 0, trailing: 16),
      titleOverflowMode: .wrap,
      largeTextLayoutStrategy: .automatic,
      minimumItemHeight: 44,
      preferredBarHeight: nil,
      widthMode: .constrained(min: 72, max: 112)
    )
  )

  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeLongTitleItems(), selectedIndex: 1, configuration: configuration)
  private let strategyControl = UISegmentedControl(items: ["Auto", "Truncate", "Shrink", "Wrap", "Wrap+Height"])
  private let infoLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic Type"
    view.backgroundColor = .systemBackground

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    ])

    let stack = FKTabBarExampleSupport.makeRootStack(
      in: view,
      scrollTopBelow: tabView.bottomAnchor,
      scrollTopSpacing: 16
    )
    view.bringSubviewToFront(tabView)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Dynamic Type strategies"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Narrow tab widths below preview truncate/shrink/wrap at the default text size. `Wrap+Height` additionally grows bar height only when the system text size is in an accessibility category (Settings → Larger Text)."))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("FKTabBar is a UIView component. It reacts to trait changes but does not provide a controller/pager wrapper."))

    strategyControl.selectedSegmentIndex = 0
    strategyControl.addAction(UIAction { [weak self] _ in
      self?.applyStrategy()
    }, for: .valueChanged)
    stack.addArrangedSubview(strategyControl)

    infoLabel.font = .preferredFont(forTextStyle: .footnote)
    infoLabel.textColor = .secondaryLabel
    infoLabel.numberOfLines = 0
    stack.addArrangedSubview(infoLabel)

    applyStrategy()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      applyStrategy()
    }
  }

  private func applyStrategy() {
    switch strategyControl.selectedSegmentIndex {
    case 1:
      configuration.layout.largeTextLayoutStrategy = .truncate
      configuration.layout.titleOverflowMode = .truncate
    case 2:
      configuration.layout.largeTextLayoutStrategy = .shrink(minimumScaleFactor: 0.78)
      configuration.layout.titleOverflowMode = .shrink(minimumScaleFactor: 0.78)
    case 3:
      configuration.layout.largeTextLayoutStrategy = .wrap(maxLines: 2)
      configuration.layout.titleOverflowMode = .wrap
    case 4:
      configuration.layout.largeTextLayoutStrategy = .wrapAndIncreaseHeight(maxLines: 2)
      configuration.layout.titleOverflowMode = .wrap
      configuration.layout.preferredBarHeight = 56
    default:
      configuration.layout.largeTextLayoutStrategy = .automatic
      configuration.layout.titleOverflowMode = .wrap
      configuration.layout.preferredBarHeight = nil
    }

    tabView.configuration = configuration
    tabView.invalidateIntrinsicContentSize()
    view.setNeedsLayout()

    let category = traitCollection.preferredContentSizeCategory
    let accessibilityNote = category.isAccessibilityCategory
      ? "accessibility text size active"
      : "default text size — Wrap+Height matches Wrap until Larger Text is increased"
    infoLabel.text = "Strategy: \(configuration.layout.largeTextLayoutStrategy)\nText size: \(category.rawValue) (\(accessibilityNote))"
  }
}
