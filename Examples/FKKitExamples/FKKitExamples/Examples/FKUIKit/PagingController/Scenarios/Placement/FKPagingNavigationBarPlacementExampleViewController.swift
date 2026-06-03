import UIKit
import FKUIKit

/// ``FKPagingTabBarPlacement/navigationBar`` — half-height pager preview with an inline configuration panel.
@MainActor
final class FKPagingNavigationBarPlacementExampleViewController: UIViewController {
  private enum TabStyle: Int {
    case segmented
    case scrollable
  }

  private enum IndicatorStyle: Int, CaseIterable {
    case styleDefault
    case none
    case lineProgress
    case lineThemeOverride
    case background
    case gradient
    case pill
    case customBehind
    case customOverlay

    var title: String {
      switch self {
      case .styleDefault: return "Default"
      case .none: return "None"
      case .lineProgress: return "Line"
      case .lineThemeOverride: return "Theme"
      case .background: return "Background"
      case .gradient: return "Gradient"
      case .pill: return "Pill"
      case .customBehind: return "Custom ↓"
      case .customOverlay: return "Custom ↑"
      }
    }
  }

  private enum PreferredHeight: Int {
    case compact = 28
    case standard = 32
    case roomy = 36
  }

  private enum HorizontalInset: Int, CaseIterable {
    case zero = 0
    case small = 8
    case medium = 16
    case large = 24
  }

  private enum SelectionScroll: Int {
    case minimal
    case center
    case leading
  }

  private let pagingController: FKPagingController
  private let showcaseCustomization = FKPagingNavigationBarShowcaseCustomization()

  private let statusLabel = UILabel()
  private let tabStyleControl = UISegmentedControl(items: ["Segmented", "Scrollable"])
  private let indicatorControl = UISegmentedControl(items: IndicatorStyle.allCases.map(\.title))
  private let insetControl = UISegmentedControl(items: HorizontalInset.allCases.map { "\($0.rawValue)" })
  private let heightControl = UISegmentedControl(items: ["Auto", "28", "32", "36"])
  private let scrollPositionControl = UISegmentedControl(items: ["Minimal", "Center", "Leading"])
  private let alignmentControl = UISegmentedControl(items: ["Follow", "Center"])
  private let suppressTitleSwitch = UISwitch()
  private let swipePagingSwitch = UISwitch()
  private let scrollFadeSwitch = UISwitch()

  private var tabStyle: TabStyle = .scrollable
  private var indicatorStyle: IndicatorStyle = .styleDefault
  private var usesAutomaticNavBarHeight = false
  private var preferredHeight: PreferredHeight = .standard
  private var horizontalInset: HorizontalInset = .zero
  private var selectionScroll: SelectionScroll = .minimal
  private var suppressesHostTitle = true
  private var allowsSwipePaging = true
  private var scrollEdgeFadeEnabled = true

  init() {
    let tabs = FKPagingNavigationBarPlacementExampleSupport.makeShowcaseTabs()
    let pages = FKPagingNavigationBarPlacementExampleSupport.makeShowcasePages(for: tabs)

    var config = FKPagingConfiguration()
    config.tabBarPlacement = .navigationBar
    config.tabBarHeightPolicy = .fixed(32)
    config.gesturePolicy = .preferNavigationBackGesture(edgeWidth: 24)

    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      tabConfiguration: FKTabBarPresets.navigationBarScrollable(),
      configuration: config
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Host screen title"
    view.backgroundColor = .systemGroupedBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    pagingController.view.clipsToBounds = true
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)
    pagingController.tabBarNavigationHost = self
    pagingController.tabBar.customization = showcaseCustomization
    pagingController.tabBar.badgeConfiguration = FKBadgeConfiguration(maxDisplayCount: 99)

    let controls = buildControlsPanel()
    controls.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(controls)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

      controls.topAnchor.constraint(equalTo: pagingController.view.bottomAnchor),
      controls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      controls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      controls.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    wireControls()
    applyTabBarConfiguration()
    applyNavigationOptions()
    refreshStatus()
  }

  private func buildControlsPanel() -> UIView {
    let scrollView = UIScrollView()
    scrollView.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)

    let caption = UILabel()
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.numberOfLines = 0
    caption.text =
      "Tabs live in navigationItem.titleView (\(FKPagingNavigationBarPlacementExampleSupport.makeShowcaseTabs().count) mixed styles). "
      + "Pager preview uses the top half; adjust placement options below. Set tabBarNavigationHost when embedding as a child VC."

    statusLabel.font = .preferredFont(forTextStyle: .caption1)
    statusLabel.textColor = .tertiaryLabel
    statusLabel.numberOfLines = 0

    let navRow = UIStackView()
    navRow.axis = .horizontal
    navRow.spacing = 8
    navRow.distribution = .fillEqually
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Prev") { [weak self] in
      self?.stepSelection(by: -1)
    })
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Next") { [weak self] in
      self?.stepSelection(by: 1)
    })
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("First") { [weak self] in
      self?.pagingController.setSelectedIndex(0, animated: true)
    })
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Last") { [weak self] in
      guard let self else { return }
      let last = max(0, pagingController.pageCount - 1)
      pagingController.setSelectedIndex(last, animated: true)
    })

    stack.addArrangedSubview(caption)
    stack.addArrangedSubview(statusLabel)
    stack.addArrangedSubview(labeledControl("Tab strip preset", tabStyleControl))
    stack.addArrangedSubview(labeledControl("Indicator", indicatorControl))
    stack.addArrangedSubview(labeledControl("Horizontal inset (pt)", insetControl))
    stack.addArrangedSubview(labeledControl("tabBarHeightPolicy · preferredHeight floor", heightControl))
    stack.addArrangedSubview(switchRow("Suppress host title", suppressTitleSwitch))
    stack.addArrangedSubview(switchRow("allowsSwipePaging", swipePagingSwitch))
    stack.addArrangedSubview(labeledControl("selectionScrollPosition", scrollPositionControl))
    stack.addArrangedSubview(labeledControl("tabAlignment", alignmentControl))
    stack.addArrangedSubview(switchRow("scrollEdgeFade (scrollable)", scrollFadeSwitch))
    stack.addArrangedSubview(navRow)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
    ])

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    let container = UIView()
    container.backgroundColor = .systemGroupedBackground
    container.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: container.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    return container
  }

  private func labeledControl(_ title: String, _ control: UIControl) -> UIStackView {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.text = title
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .vertical
    row.spacing = 6
    return row
  }

  private func switchRow(_ title: String, _ toggle: UISwitch) -> UIStackView {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.text = title
    let spacer = UIView()
    let row = UIStackView(arrangedSubviews: [label, spacer, toggle])
    row.axis = .horizontal
    row.alignment = .center
    return row
  }

  private func wireControls() {
    tabStyleControl.selectedSegmentIndex = tabStyle.rawValue
    indicatorControl.selectedSegmentIndex = indicatorStyle.rawValue
    insetControl.selectedSegmentIndex = HorizontalInset.allCases.firstIndex(of: horizontalInset) ?? 0
    syncHeightControlSelection()
    scrollPositionControl.selectedSegmentIndex = selectionScroll.rawValue
    alignmentControl.selectedSegmentIndex = 0
    suppressTitleSwitch.isOn = suppressesHostTitle
    swipePagingSwitch.isOn = allowsSwipePaging
    scrollFadeSwitch.isOn = scrollEdgeFadeEnabled

    tabStyleControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.tabStyle = TabStyle(rawValue: control.selectedSegmentIndex) ?? .scrollable
      self.applyTabBarConfiguration()
      self.refreshStatus()
    }, for: .valueChanged)

    indicatorControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.indicatorStyle = IndicatorStyle(rawValue: control.selectedSegmentIndex) ?? .styleDefault
      self.applyTabBarConfiguration()
      self.refreshStatus()
    }, for: .valueChanged)

    insetControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      let value = HorizontalInset.allCases[control.selectedSegmentIndex]
      self.horizontalInset = value
      self.applyNavigationOptions()
    }, for: .valueChanged)

    heightControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 0:
        self.usesAutomaticNavBarHeight = true
      case 1:
        self.usesAutomaticNavBarHeight = false
        self.preferredHeight = .compact
      case 3:
        self.usesAutomaticNavBarHeight = false
        self.preferredHeight = .roomy
      default:
        self.usesAutomaticNavBarHeight = false
        self.preferredHeight = .standard
      }
      self.applyNavigationOptions()
    }, for: .valueChanged)

    suppressTitleSwitch.addAction(UIAction { [weak self] action in
      guard let self, let toggle = action.sender as? UISwitch else { return }
      self.suppressesHostTitle = toggle.isOn
      self.applyNavigationOptions()
    }, for: .valueChanged)

    swipePagingSwitch.addAction(UIAction { [weak self] action in
      guard let self, let toggle = action.sender as? UISwitch else { return }
      self.allowsSwipePaging = toggle.isOn
      self.pagingController.configuration.allowsSwipePaging = toggle.isOn
      self.refreshStatus()
    }, for: .valueChanged)

    scrollPositionControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.selectionScroll = SelectionScroll(rawValue: control.selectedSegmentIndex) ?? .minimal
      self.applyTabBarConfiguration()
      self.refreshStatus()
    }, for: .valueChanged)

    alignmentControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.pagingController.configuration.tabAlignment = control.selectedSegmentIndex == 1 ? .alwaysCenter : .followTabBarDefault
      self.refreshStatus()
    }, for: .valueChanged)

    scrollFadeSwitch.addAction(UIAction { [weak self] action in
      guard let self, let toggle = action.sender as? UISwitch else { return }
      self.scrollEdgeFadeEnabled = toggle.isOn
      self.applyTabBarConfiguration()
      self.refreshStatus()
    }, for: .valueChanged)
  }

  private func stepSelection(by delta: Int) {
    let next = min(max(0, pagingController.selectedIndex + delta), max(0, pagingController.pageCount - 1))
    pagingController.setSelectedIndex(next, animated: true)
  }

  private func applyNavigationOptions() {
    let floorHeight = CGFloat(preferredHeight.rawValue)
    pagingController.configuration.tabBarPlacement = .navigationBar(
      FKPagingNavigationBarTabOptions(
        horizontalInset: CGFloat(horizontalInset.rawValue),
        preferredHeight: floorHeight,
        suppressesHostTitle: suppressesHostTitle
      )
    )
    pagingController.configuration.tabBarHeightPolicy = usesAutomaticNavBarHeight
      ? .automatic
      : .fixed(floorHeight)
    refreshStatus()
  }

  private func syncHeightControlSelection() {
    if usesAutomaticNavBarHeight {
      heightControl.selectedSegmentIndex = 0
      return
    }
    heightControl.selectedSegmentIndex = switch preferredHeight {
    case .compact: 1
    case .standard: 2
    case .roomy: 3
    }
  }

  private func applyTabBarConfiguration() {
    var configuration = baseTabConfiguration()
    if indicatorStyle != .styleDefault {
      configuration.appearance = Self.makeIndicatorAppearance(for: indicatorStyle)
    }

    switch selectionScroll {
    case .minimal:
      configuration.layout.selectionScrollPosition = .minimalVisible
    case .center:
      configuration.layout.selectionScrollPosition = .center
    case .leading:
      configuration.layout.selectionScrollPosition = .leading
    }

    configuration.layout.scrollEdgeFade.isEnabled = scrollEdgeFadeEnabled && tabStyle == .scrollable
    pagingController.tabBar.applyConfiguration(configuration)
  }

  private func baseTabConfiguration() -> FKTabBarConfiguration {
    switch tabStyle {
    case .segmented:
      return FKTabBarPresets.navigationBarSegmented()
    case .scrollable:
      return FKTabBarPresets.navigationBarScrollable()
    }
  }

  private func refreshStatus() {
    let styleText = tabStyle == .segmented ? "segmented" : "scrollable"
    let titleText = suppressesHostTitle ? "hidden" : "visible"
    let scrollText = switch selectionScroll {
    case .minimal: "minimalVisible"
    case .center: "center"
    case .leading: "leading"
    }
    let alignText = pagingController.configuration.tabAlignment == .alwaysCenter ? "alwaysCenter" : "followTabBarDefault"
    let heightText = usesAutomaticNavBarHeight
      ? "automatic (floor \(preferredHeight.rawValue)pt, max 44pt)"
      : "fixed \(preferredHeight.rawValue)pt"
    statusLabel.text =
      "style=\(styleText) · indicator=\(indicatorStyle.title) · inset=\(horizontalInset.rawValue)pt · height=\(heightText) · hostTitle \(titleText) · swipe=\(allowsSwipePaging) · scroll=\(scrollText) · align=\(alignText) · fade=\(scrollEdgeFadeEnabled) · selected=\(pagingController.selectedIndex + 1)/\(pagingController.pageCount)"
  }

  private static func makeIndicatorAppearance(for style: IndicatorStyle) -> FKTabBarAppearance {
    let insets = NSDirectionalEdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
    switch style {
    case .styleDefault:
      return FKTabBarPresets.navigationBarSegmented().appearance
    case .none:
      return FKTabBarAppearance(indicatorStyle: .none)
    case .lineProgress:
      return FKTabBarPresets.navigationBarScrollable().appearance
    case .lineThemeOverride:
      var appearance = FKTabBarPresets.navigationBarScrollable().appearance
      appearance.colors.selectedText = .systemOrange
      appearance.colors.indicator = .systemOrange
      if case .line(var line) = appearance.indicatorStyle {
        line.fill = .solid(.systemOrange)
        appearance.indicatorStyle = .line(line)
      }
      return appearance
    case .background:
      return FKTabBarAppearance(
        indicatorStyle: .background(
          FKTabBarBackgroundIndicatorConfiguration(
            insets: insets,
            cornerRadius: 8,
            fill: .solid(.tertiarySystemFill),
            followMode: .trackContentProgress
          )
        )
      )
    case .gradient:
      return FKTabBarAppearance(
        indicatorStyle: .gradient(
          FKTabBarBackgroundIndicatorConfiguration(
            insets: insets,
            cornerRadius: 8,
            fill: .gradient(
              colors: [.systemPink, .systemPurple],
              startPoint: .init(x: 0, y: 0.5),
              endPoint: .init(x: 1, y: 0.5)
            ),
            followMode: .trackContentProgress
          )
        )
      )
    case .pill:
      return FKTabBarAppearance(
        indicatorStyle: .pill(
          FKTabBarBackgroundIndicatorConfiguration(
            insets: insets,
            cornerRadius: 999,
            fill: .solid(.secondarySystemFill),
            followMode: .trackContentProgress
          )
        )
      )
    case .customBehind:
      return FKTabBarAppearance(
        indicatorStyle: .custom(id: "paging.demo.custom", followMode: .trackContentProgress),
        indicatorZOrder: .automatic
      )
    case .customOverlay:
      return FKTabBarAppearance(
        indicatorStyle: .custom(id: "paging.demo.custom", followMode: .trackContentProgress),
        indicatorZOrder: .aboveTabItems
      )
    }
  }
}
