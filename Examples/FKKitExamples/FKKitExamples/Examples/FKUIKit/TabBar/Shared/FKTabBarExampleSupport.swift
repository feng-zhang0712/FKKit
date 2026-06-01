import UIKit
import FKUIKit

enum FKTabBarExampleSupport {
  static func makeItems(_ count: Int, localizedTitles: [String]? = nil) -> [FKTabBarItem] {
    let baseTitles = localizedTitles ?? [
      NSLocalizedString("Home", comment: ""),
      NSLocalizedString("Explore", comment: ""),
      NSLocalizedString("Inbox", comment: ""),
      NSLocalizedString("Profile", comment: ""),
      NSLocalizedString("Settings", comment: ""),
      NSLocalizedString("Video", comment: ""),
      NSLocalizedString("Shop", comment: ""),
      NSLocalizedString("Updates", comment: ""),
      NSLocalizedString("Favorites", comment: ""),
      NSLocalizedString("Archive", comment: ""),
      NSLocalizedString("More", comment: ""),
    ]
    let baseIcons = [
      "house", "safari", "tray", "person.crop.circle", "gearshape",
      "play.rectangle", "bag", "bell", "heart", "archivebox", "ellipsis.circle",
    ]
    let n = max(1, min(count, min(baseTitles.count, baseIcons.count)))
    return (0..<n).map { idx in
      FKTabBarItem(
        id: "tab-\(idx)",
        title: .init(normal: .init(text: baseTitles[idx])),
        image: .init(normal: .init(source: .systemSymbol(name: baseIcons[idx]))),
        accessibilityLabel: baseTitles[idx]
      )
    }
  }

  static func makeLongTitleItems() -> [FKTabBarItem] {
    let titles = [
      "Overview",
      "Very Long Financial Dashboard",
      "Notifications Center and Activity Feed",
      "Account Preferences and Privacy",
      "Experimental Feature Flags",
      "Insights",
      "Security",
      "Support",
      "History",
      "Downloads",
      "About This Application",
    ]
    return makeItems(titles.count, localizedTitles: titles)
  }

  static func makeMixedContentItems() -> [FKTabBarItem] {
    [
      FKTabBarItem(id: "text", title: .init(normal: .init(text: "Text"))),
      FKTabBarItem(
        id: "symbol",
        title: .init(normal: .init(text: "Symbol")),
        image: .init(normal: .init(source: .systemSymbol(name: "paperplane.fill"))),
        accessibilityLabel: "System symbol"
      ),
      FKTabBarItem(
        id: "image",
        title: .init(
          normal: .init(text: "Image"),
          selected: .init(text: "Image tab with long text")
        ),
        image: .init(
          normal: .init(source: .systemSymbol(name: "person.crop.circle")),
          selected: .init(source: .systemSymbol(name: "photo"))
        )
      ),
      FKTabBarItem(
        id: "custom",
        title: .init(normal: .init(text: "Custom")),
        customContentIdentifier: "pill",
        accessibilityLabel: "Custom content"
      ),
    ]
  }

  /// Hosts a vertical `UIStackView` inside a full-screen `UIScrollView`.
  ///
  /// - Parameters:
  ///   - topInset: Used when `scrollTopBelow` is `nil`; pins the scroll view top to `safeAreaLayoutGuide` plus this inset.
  ///   - scrollTopBelow: When non-`nil`, pins the scroll view top to this anchor (for example the bottom of a pinned `FKTabBar`) so scroll content is not covered by overlay tab bars.
  ///   - scrollTopSpacing: Extra vertical space between `scrollTopBelow` and the scroll view top.
  ///   - scrollBottomAbove: When non-`nil`, pins the scroll view bottom to this anchor (for example the top of a bottom-docked `FKTabBar`).
  ///   - scrollBottomSpacing: Extra vertical space between the scroll view bottom and `scrollBottomAbove`.
  static func makeRootStack(
    in view: UIView,
    topInset: CGFloat = 66,
    scrollTopBelow referenceAnchor: NSLayoutYAxisAnchor? = nil,
    scrollTopSpacing: CGFloat = 16,
    scrollBottomAbove bottomReferenceAnchor: NSLayoutYAxisAnchor? = nil,
    scrollBottomSpacing: CGFloat = 0
  ) -> UIStackView {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(stack)

    let scrollTopConstraint: NSLayoutConstraint = {
      if let referenceAnchor {
        return scrollView.topAnchor.constraint(equalTo: referenceAnchor, constant: scrollTopSpacing)
      }
      return scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset)
    }()
    let scrollBottomConstraint: NSLayoutConstraint = {
      if let bottomReferenceAnchor {
        return scrollView.bottomAnchor.constraint(equalTo: bottomReferenceAnchor, constant: -scrollBottomSpacing)
      }
      return scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    }()

    NSLayoutConstraint.activate([
      scrollTopConstraint,
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollBottomConstraint,

      stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
      stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])

    return stack
  }

  static func titleLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func captionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func actionButton(_ title: String, onTap: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    var config = UIButton.Configuration.plain()
    config.title = title
    config.baseForegroundColor = .systemBlue
    config.background.backgroundColor = .secondarySystemFill
    config.background.cornerRadius = 10
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    button.configuration = config
    button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
    return button
  }

  /// Pins a tab strip below the host safe-area top edge.
  ///
  /// - Returns: The height constraint so callers can adjust bar height at runtime (for example ``FKTabBarPresets/bottomDocked(showsIndicator:)``).
  @discardableResult
  static func attachPinnedTabBar(
    _ tabBar: UIView,
    to hostView: UIView,
    height: CGFloat = 52
  ) -> NSLayoutConstraint {
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    hostView.addSubview(tabBar)
    let heightConstraint = tabBar.heightAnchor.constraint(equalToConstant: height)
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
      tabBar.topAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.topAnchor),
      heightConstraint,
    ])
    return heightConstraint
  }
}

// MARK: - Example customizations

/// Supplies the pill custom content used by ``FKTabBarExampleSupport/makeMixedContentItems()``.
@MainActor
final class FKTabBarExampleContentCustomization: FKTabBarDefaultCustomization {
  override func customContentView(for item: FKTabBarItem) -> UIView? {
    guard item.customContentIdentifier == "pill" else { return nil }
    let container = UIView()
    container.backgroundColor = .systemPurple
    container.layer.cornerRadius = 10
    container.clipsToBounds = true

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Custom"
    label.font = .systemFont(ofSize: 12, weight: .semibold)
    label.textAlignment = .center
    label.textColor = .white

    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
    ])

    container.setContentHuggingPriority(.required, for: .horizontal)
    container.setContentCompressionResistancePriority(.required, for: .horizontal)
    return container
  }
}

/// Alternating per-index widths for scrollable width demos.
@MainActor
final class FKTabBarExampleWidthCustomization: FKTabBarDefaultCustomization {
  override func customWidth(for index: Int, item: FKTabBarItem, in tabBar: FKTabBar) -> CGFloat? {
    index % 2 == 0 ? 90 : 150
  }
}

/// Host-provided indicator surface for ``FKTabBarIndicatorStyle/custom`` demos.
@MainActor
final class FKTabBarExampleIndicatorCustomization: FKTabBarDefaultCustomization {
  var indicatorID: String
  var fillColor: UIColor
  var cornerRadius: CGFloat

  init(indicatorID: String, fillColor: UIColor, cornerRadius: CGFloat = 8) {
    self.indicatorID = indicatorID
    self.fillColor = fillColor
    self.cornerRadius = cornerRadius
  }

  override func customIndicatorView(id: String) -> UIView? {
    guard id == indicatorID else { return nil }
    let view = UIView()
    view.backgroundColor = fillColor
    view.layer.cornerRadius = cornerRadius
    return view
  }
}

/// Advanced indicator hooks: follow mode resolution, custom frame, and render pass.
@MainActor
final class FKTabBarExampleAdvancedIndicatorCustomization: FKTabBarDefaultCustomization {
  let followID = "advanced.indicator"
  var usesProgressFollow = false

  override func customIndicatorView(id: String) -> UIView? {
    guard id == followID else { return nil }
    let view = UIView()
    view.backgroundColor = .systemOrange.withAlphaComponent(0.25)
    view.layer.cornerRadius = 10
    view.layer.borderWidth = 2
    view.layer.borderColor = UIColor.systemOrange.cgColor
    return view
  }

  override func renderCustomIndicator(id: String, bounds: CGRect, container: UIView) {
    guard id == followID else { return }
    container.subviews.forEach { $0.frame = bounds.insetBy(dx: 4, dy: 4) }
  }

  override func customIndicatorFrame(itemFrame: CGRect, containerBounds: CGRect) -> CGRect? {
    itemFrame.insetBy(dx: -6, dy: -4)
  }

  override func indicatorFollowMode(forCustomID id: String) -> FKTabBarIndicatorFollowMode? {
    guard id == followID else { return nil }
    return usesProgressFollow ? .trackContentProgress : .trackSelectedFrame
  }
}

/// Interaction, accessory, and tap-scale hooks.
@MainActor
final class FKTabBarExampleHooksCustomization: FKTabBarDefaultCustomization {
  override func customAccessoryView(for item: FKTabBarItem, isSelected: Bool, isExpanded: Bool) -> UIView? {
    guard case .custom(let id) = item.accessory.kind, id == "star" else { return nil }
    let label = UILabel()
    label.text = isExpanded ? "★" : "☆"
    label.font = .systemFont(ofSize: 14, weight: .bold)
    label.textColor = isSelected ? .systemOrange : .secondaryLabel
    return label
  }

  override func animateInteraction(on button: FKButton, phase: FKTabBar.ItemInteractionPhase, item: FKTabBarItem) {
    let scale: CGFloat = phase == .tap ? 0.94 : 0.9
    UIView.animate(withDuration: 0.12, animations: {
      button.transform = CGAffineTransform(scaleX: scale, y: scale)
    }, completion: { _ in
      UIView.animate(withDuration: 0.12) {
        button.transform = .identity
      }
    })
  }
}

