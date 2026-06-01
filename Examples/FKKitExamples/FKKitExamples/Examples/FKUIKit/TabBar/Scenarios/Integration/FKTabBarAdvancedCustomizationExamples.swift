import UIKit
import FKUIKit

// MARK: - Indicator advanced (z-order, follow mode, custom frame)

final class FKTabBarIndicatorAdvancedExampleViewController: UIViewController {
  private var configuration = FKTabBarPresets.pagerHeader()
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(6), selectedIndex: 0, configuration: configuration)
  private let customization = FKTabBarExampleAdvancedIndicatorCustomization()
  private let logLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indicator advanced"
    view.backgroundColor = .systemBackground

    tabView.customization = customization

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Z-order, custom follow mode, custom frame"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Uses customIndicatorView, renderCustomIndicator, customIndicatorFrame, and indicatorFollowMode(forCustomID:)."))

    let zOrder = UISegmentedControl(items: ["Auto", "Below", "Above"])
    zOrder.selectedSegmentIndex = 0
    zOrder.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 1: self.configuration.appearance.indicatorZOrder = .belowTabItems
      case 2: self.configuration.appearance.indicatorZOrder = .aboveTabItems
      default: self.configuration.appearance.indicatorZOrder = .automatic
      }
      self.tabView.configuration = self.configuration
      self.log("indicatorZOrder updated")
    }, for: .valueChanged)
    stack.addArrangedSubview(zOrder)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Toggle trackContentProgress follow") { [weak self] in
      guard let self else { return }
      self.customization.usesProgressFollow.toggle()
      self.configuration.appearance.indicatorStyle = .custom(
        id: self.customization.followID,
        followMode: .custom(id: self.customization.followID)
      )
      self.tabView.configuration = self.configuration
      self.log("followMode => \(self.customization.usesProgressFollow ? "trackContentProgress" : "trackSelectedFrame")")
    })

    logLabel.font = .preferredFont(forTextStyle: .footnote)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    stack.addArrangedSubview(logLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 52),
    ])

    configuration.appearance.indicatorStyle = .custom(
      id: customization.followID,
      followMode: .custom(id: customization.followID)
    )
    tabView.configuration = configuration
    log("Ready")
  }

  private func log(_ message: String) {
    logLabel.text = message
  }
}

// MARK: - Customization hooks

final class FKTabBarCustomizationHooksExampleViewController: UIViewController {
  private let customization = FKTabBarExampleHooksCustomization()
  private lazy var tabView: FKTabBar = {
    var items = FKTabBarExampleSupport.makeItems(4)
    items[0].accessory = FKTabBarAccessoryConfiguration(kind: .custom(id: "star"))
    var config = FKTabBarPresets.segmentedControl(itemSpacing: 12)
    let bar = FKTabBar(items: items, selectedIndex: 0, configuration: config)
    bar.customization = customization
    bar.badgeConfiguration = FKBadgeConfiguration(maxDisplayCount: 9)
    bar.badgeAnimation = .pop()
    bar.shouldSelect = { [weak self] item, index, reason in
      self?.log("shouldSelect closure: \(item.id) @\(index) reason=\(reason)")
      return index != 2
    }
    return bar
  }()
  private let logLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Customization hooks"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("animateInteraction, customAccessory, shouldSelect, badge config"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab index 2 is blocked by shouldSelect closure. Long-press any tab. Tap chevron accessory on tab-0."))

    tabView.isLongPressEnabled = true
    tabView.onLongPress = { [weak self] item, index in
      self?.log("onLongPress: \(item.id) @\(index)")
    }

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Toggle expandedItemID tab-0") { [weak self] in
      guard let self else { return }
      self.tabView.expandedItemID = self.tabView.expandedItemID == "tab-0" ? nil : "tab-0"
      self.log("expandedItemID = \(self.tabView.expandedItemID ?? "nil")")
    })

    logLabel.font = .preferredFont(forTextStyle: .footnote)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    stack.addArrangedSubview(logLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 52),
    ])

    tabView.setBadge(.count(3), at: 1)
    log("Ready — try tab-2 (blocked), long-press, accessory")
  }

  private func log(_ message: String) {
    logLabel.text = message
  }
}

// MARK: - performBatchUpdates

final class FKTabBarBatchUpdatesExampleViewController: UIViewController {
  private var configuration = FKTabBarPresets.pagerHeader()
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(4), selectedIndex: 0, configuration: configuration)
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Batch updates"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("performBatchUpdates(_:completion:)"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Applies configuration + badge + tint changes with one layout invalidation."))

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Apply theme batch") { [weak self] in
      guard let self else { return }
      self.tabView.performBatchUpdates {
        var appearance = self.configuration.appearance
        appearance.colors.selectedText = .systemPink
        appearance.colors.normalText = .secondaryLabel
        self.configuration.appearance = appearance
        self.tabView.configuration = self.configuration
        self.tabView.setBadge(.dot, at: 0)
      } completion: {
        self.statusLabel.text = "Batch complete — pink selected titles + dot badge on tab-0"
      }
    })

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Tap to run batch"
    stack.addArrangedSubview(statusLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 52),
    ])
  }
}
