import UIKit
import FKUIKit

// MARK: - Item insets & indicator content frame

/// Adjusts ``FKTabBarLayoutConfiguration/itemInsets`` and shows indicator ``trackContentFrame`` alignment.
final class FKTabBarItemInsetsExampleViewController: UIViewController {
  private var configuration: FKTabBarConfiguration = {
    var config = FKTabBarPresets.pagerHeader()
    if case .line(var line) = config.appearance.indicatorStyle {
      line.followMode = .trackSelectedFrame
      config.appearance.indicatorStyle = .line(line)
    }
    return config
  }()
  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeItems(4),
    selectedIndex: 0,
    configuration: configuration
  )
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Item insets"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Per-tab itemInsets"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Adjusts itemInsets on all four edges at once (top, leading, bottom, trailing). Line indicator follows the cell frame (trackSelectedFrame)."
      )
    )

    let slider = UISlider()
    slider.minimumValue = 0
    slider.maximumValue = 24
    slider.value = Float(configuration.layout.itemInsets.leading)
    slider.addAction(UIAction { [weak self] _ in
      self?.applyInsets(CGFloat(slider.value))
    }, for: .valueChanged)
    stack.addArrangedSubview(slider)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    stack.addArrangedSubview(statusLabel)
    applyInsets(CGFloat(slider.value))

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }

  private func applyInsets(_ value: CGFloat) {
    let inset = NSDirectionalEdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    configuration.layout.itemInsets = inset
    tabView.applyConfiguration(configuration)
    statusLabel.text = String(format: "itemInsets = %.0f pt on all edges", value)
  }
}

// MARK: - Content alignment

/// Non-scrollable strip with extra horizontal space — compares ``FKTabBarContentAlignment`` values.
final class FKTabBarContentAlignmentExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(
    layout: .init(
      isScrollable: false,
      itemSpacing: 8,
      contentInsets: .zero,
      contentAlignment: .center,
      widthMode: .intrinsic
    )
  )
  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeItems(3),
    selectedIndex: 0,
    configuration: configuration
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content alignment"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("contentAlignment matrix"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Applies when the strip is not scrollable and total tab width is smaller than available width. Strip contentInsets are zero here; Leading/Trailing intentionally place extra space on the opposite edge."
      )
    )

    let modes: [(String, FKTabBarContentAlignment)] = [
      ("Leading", .leading),
      ("Center", .center),
      ("Trailing", .trailing),
    ]
    modes.forEach { title, mode in
      stack.addArrangedSubview(FKTabBarExampleSupport.actionButton(title) { [weak self] in
        self?.configuration.layout.contentAlignment = mode
        self?.tabView.applyConfiguration(self?.configuration ?? .init())
      })
    }

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }
}

// MARK: - Scroll edge fade

final class FKTabBarScrollEdgeFadeExampleViewController: UIViewController {
  private var configuration: FKTabBarConfiguration = {
    var config = FKTabBarPresets.filterStrip()
    config.layout.isScrollable = true
    config.layout.scrollEdgeFade = .init(isEnabled: true, width: 40)
    return config
  }()

  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeItems(8),
    selectedIndex: 4,
    configuration: configuration
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scroll edge fade"
    view.backgroundColor = .systemBackground

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)

    let stack = FKTabBarExampleSupport.makeRootStack(
      in: view,
      scrollTopBelow: tabView.bottomAnchor,
      scrollTopSpacing: 16
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("scrollEdgeFade"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Gradient masks fade tab labels at the clipped leading/trailing edges while you scroll. Swipe the strip horizontally — the left and right fades appear when more tabs sit off-screen."
      )
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Toggle fade") { [weak self] in
      guard let self else { return }
      self.configuration.layout.scrollEdgeFade.isEnabled.toggle()
      self.tabView.applyConfiguration(self.configuration)
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Fade width 16 / 40") { [weak self] in
      guard let self else { return }
      let next: CGFloat = self.configuration.layout.scrollEdgeFade.width <= 20 ? 40 : 16
      self.configuration.layout.scrollEdgeFade.width = next
      self.tabView.applyConfiguration(self.configuration)
    })

    tabView.layoutIfNeeded()
  }
}

// MARK: - Stable ID APIs

final class FKTabBarStableIDExampleViewController: UIViewController {
  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeItems(4),
    selectedIndex: 0,
    configuration: FKTabBarPresets.pagerHeader()
  )
  private let logLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Stable ID APIs"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Select / badge / update by ID"))
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select tab-2 by ID") { [weak self] in
      guard let self else { return }
      let ok = self.tabView.setSelectedIndex(forItemID: "tab-2", animated: true)
      self.log("setSelectedIndex(forItemID: tab-2) => \(ok)")
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Badge tab-1 count 7") { [weak self] in
      self?.tabView.setBadge(.count(7), forItemID: "tab-1")
      self?.log("setBadge(forItemID: tab-1)")
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("setItem(forItemID: tab-0)") { [weak self] in
      guard let self else { return }
      var item = self.tabView.visibleItems.first(where: { $0.id == "tab-0" }) ?? FKTabBarItem(id: "tab-0")
      item.title.normal.text = "Home*"
      _ = self.tabView.setItem(item, forItemID: "tab-0")
      self.log("Title patched via setItem(forItemID:)")
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("reapplyVisibleItemConfigurations()") { [weak self] in
      self?.tabView.reapplyVisibleItemConfigurations()
      self?.log("Re-applied visible cell models")
    })

    logLabel.font = .preferredFont(forTextStyle: .footnote)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Ready."
    stack.addArrangedSubview(logLabel)

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }

  private func log(_ message: String) {
    logLabel.text = message
  }
}

// MARK: - Long press & resolved title presentation

final class FKTabBarLongPressExampleViewController: UIViewController {
  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(
      items: FKTabBarExampleSupport.makeItems(4),
      selectedIndex: 0,
      configuration: FKTabBarPresets.pagerHeader()
    )
    tab.isLongPressEnabled = true
    tab.isHapticFeedbackEnabled = true
    tab.onLongPress = { [weak self] item, index in
      self?.log("Long-pressed \(item.id) at \(index)")
    }
    return tab
  }()

  private let logLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long press"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Long-press + title presentation"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Long-press is opt-in. resolvedTitlePresentationForCurrentEnvironment() exposes effective overflow/line policy."
      )
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Log resolved title presentation") { [weak self] in
      guard let self else { return }
      let resolved = self.tabView.resolvedTitlePresentationForCurrentEnvironment()
      self.log("overflow=\(resolved.overflowMode) lines=\(resolved.maximumTitleLines) growHeight=\(resolved.shouldIncreaseBarHeight)")
    })

    logLabel.font = .preferredFont(forTextStyle: .footnote)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Long-press any tab."
    stack.addArrangedSubview(logLabel)

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }

  private func log(_ message: String) {
    logLabel.text = message
  }
}

// MARK: - Custom badge

private final class FKTabBarDemoDotBadgeView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .systemPink
    layer.cornerRadius = 5
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: 10),
      heightAnchor.constraint(equalToConstant: 10),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class FKTabBarCustomBadgeCustomization: FKTabBarDefaultCustomization {
  override func customBadgeView(for item: FKTabBarItem) -> UIView? {
    FKTabBarDemoDotBadgeView()
  }
}

final class FKTabBarCustomBadgeExampleViewController: UIViewController {
  private lazy var tabView: FKTabBar = {
    var items = FKTabBarExampleSupport.makeItems(3)
    items[1].badge.state.normal = .custom(id: "pink-dot")
    return FKTabBar(
      items: items,
      selectedIndex: 0,
      configuration: FKTabBarPresets.pagerHeader()
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom badge"
    view.backgroundColor = .systemBackground
    tabView.customization = FKTabBarCustomBadgeCustomization()

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("FKTabBarBadgeContent.custom"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Supply ``FKTabBarCustomization/customBadgeView(for:)`` when badge state is `.custom(id:)`."
      )
    )

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }
}

// MARK: - Per-index spacing

private final class FKTabBarVariableSpacingCustomization: FKTabBarDefaultCustomization {
  override func customSpacing(after index: Int, context: FKTabBarLayoutConfiguration.SpacingContext) -> CGFloat? {
    index == 0 ? 24 : 8
  }
}

final class FKTabBarCustomSpacingExampleViewController: UIViewController {
  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(
      items: FKTabBarExampleSupport.makeItems(4),
      selectedIndex: 0,
      configuration: FKTabBarPresets.pagerHeader()
    )
    tab.customization = FKTabBarVariableSpacingCustomization()
    return tab
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom spacing"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("customSpacing(after:)"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Gap after index 0 is 24pt; other gaps use 8pt. Per-index spacing is honored by the internal flow layout."
      )
    )

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }
}

// MARK: - Global subtitle fallback

final class FKTabBarGlobalSubtitleExampleViewController: UIViewController {
  private lazy var tabView: FKTabBar = {
    var appearance = FKTabBarAppearance()
    appearance.subtitleConfiguration = .init(
      normal: .init(text: "Global subtitle", style: .init(font: .preferredFont(forTextStyle: .caption2), color: .secondaryLabel))
    )
    var config = FKTabBarPresets.pagerHeader()
    config.appearance = appearance
    return FKTabBar(items: FKTabBarExampleSupport.makeItems(3), selectedIndex: 0, configuration: config)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global subtitle"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("appearance.subtitleConfiguration"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Used when ``FKTabBarItem/subtitle`` is nil. Item-level subtitle overrides the global default. Selected tabs inherit ``FKTabBarAppearance/colors/selectedText`` when no subtitle selected style is set."
      )
    )

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }
}
