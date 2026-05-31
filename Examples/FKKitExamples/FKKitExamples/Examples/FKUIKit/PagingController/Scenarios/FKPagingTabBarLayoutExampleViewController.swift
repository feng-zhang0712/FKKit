import UIKit
import FKUIKit

/// ``FKPagingController`` with live ``FKTabBarLayoutConfiguration`` controls for width, selection scroll, and content alignment.
@MainActor
final class FKPagingTabBarLayoutExampleViewController: UIViewController {
  private enum StripDataset: Int {
    case scrollableLong
    case compactAlignment
  }

  private enum WidthDemo: Int {
    case intrinsic
    case fixed
    case fillEqually
    case constrained
  }

  private enum ScrollDemo: Int {
    case minimal
    case center
    case leading
    case trailing
  }

  private enum AlignmentDemo: Int {
    case leading
    case center
    case trailing
    case spaceBetween
    case spaceAround
    case spaceEvenly
  }

  private let pagingController: FKPagingController
  private let statusLabel = UILabel()
  private let stripDatasetControl = UISegmentedControl(items: ["Long strip", "Compact strip"])
  private let widthControl = UISegmentedControl(items: ["Intrinsic", "Fixed", "Fill", "Range"])
  private let scrollControl = UISegmentedControl(items: ["Minimal", "Center", "Lead", "Trail"])
  private let alignmentControl = UISegmentedControl(items: ["Lead", "Center", "Trail", "Between", "Around", "Evenly"])

  private var stripDataset: StripDataset = .scrollableLong
  private var widthDemo: WidthDemo = .intrinsic
  private var scrollDemo: ScrollDemo = .center
  private var alignmentDemo: AlignmentDemo = .leading

  init() {
    let tabs = Self.makeTabs(for: .scrollableLong)
    let pages = Self.makePages(count: tabs.filter { !$0.isHidden }.count)
    var tabConfiguration = FKTabBarPresets.pagerHeader()
    tabConfiguration.layout.isScrollable = true
    tabConfiguration.layout.widthMode = .intrinsic
    tabConfiguration.layout.selectionScrollPosition = .center
    tabConfiguration.layout.contentAlignment = .leading

    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: 0,
      tabConfiguration: tabConfiguration,
      configuration: FKPagingConfiguration(
        tabBarHeightPolicy: .automatic,
        tabAlignment: .followTabBarDefault
      )
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tab bar layout"
    view.backgroundColor = .systemGroupedBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)

    let controls = buildControlsPanel()
    controls.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(controls)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      controls.topAnchor.constraint(equalTo: pagingController.view.bottomAnchor),
      controls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      controls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      controls.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      pagingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.48),
    ])

    wireControls()
    applyLayoutSettings(reloadStrip: false)
  }

  private func buildControlsPanel() -> UIView {
    let scrollView = UIScrollView()
    scrollView.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)

    let caption = UILabel()
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.numberOfLines = 0
    caption.text =
      "Mutate ``FKTabBar/configuration/layout`` on ``FKPagingController/tabBar``. Width mode and selection scroll apply while swiping or tapping tabs. Content alignment applies only when width ≠ fillEqually and items fit without scrolling — use Compact strip."

    statusLabel.font = .preferredFont(forTextStyle: .caption1)
    statusLabel.textColor = .tertiaryLabel
    statusLabel.numberOfLines = 0

    let navRow = UIStackView()
    navRow.axis = .horizontal
    navRow.spacing = 8
    navRow.distribution = .fillEqually
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Prev tab") { [weak self] in
      self?.stepSelection(by: -1)
    })
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Next tab") { [weak self] in
      self?.stepSelection(by: 1)
    })
    navRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Jump last") { [weak self] in
      guard let self else { return }
      let last = max(0, pagingController.pageCount - 1)
      pagingController.setSelectedIndex(last, animated: true)
    })

    stack.addArrangedSubview(caption)
    stack.addArrangedSubview(statusLabel)
    stack.addArrangedSubview(labeledControl("Strip data", stripDatasetControl))
    stack.addArrangedSubview(labeledControl("widthMode", widthControl))
    stack.addArrangedSubview(labeledControl("selectionScrollPosition", scrollControl))
    stack.addArrangedSubview(labeledControl("contentAlignment", alignmentControl))
    stack.addArrangedSubview(navRow)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
    ])

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    let container = UIView()
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

  private func wireControls() {
    stripDatasetControl.selectedSegmentIndex = stripDataset.rawValue
    widthControl.selectedSegmentIndex = widthDemo.rawValue
    scrollControl.selectedSegmentIndex = scrollDemo.rawValue
    alignmentControl.selectedSegmentIndex = alignmentDemo.rawValue

    stripDatasetControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.stripDataset = StripDataset(rawValue: control.selectedSegmentIndex) ?? .scrollableLong
      self.reloadStripContent()
    }, for: .valueChanged)

    widthControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.widthDemo = WidthDemo(rawValue: control.selectedSegmentIndex) ?? .intrinsic
      self.applyLayoutSettings(reloadStrip: false)
    }, for: .valueChanged)

    scrollControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.scrollDemo = ScrollDemo(rawValue: control.selectedSegmentIndex) ?? .center
      self.applyLayoutSettings(reloadStrip: false)
    }, for: .valueChanged)

    alignmentControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.alignmentDemo = AlignmentDemo(rawValue: control.selectedSegmentIndex) ?? .leading
      self.applyLayoutSettings(reloadStrip: false)
    }, for: .valueChanged)
  }

  private func reloadStripContent() {
    let preserved = min(pagingController.selectedIndex, max(0, Self.makeTabs(for: stripDataset).filter { !$0.isHidden }.count - 1))
    let tabs = Self.makeTabs(for: stripDataset)
    let pages = Self.makePages(count: tabs.filter { !$0.isHidden }.count)
    pagingController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: preserved)
    applyLayoutSettings(reloadStrip: false)
  }

  private func applyLayoutSettings(reloadStrip: Bool) {
    if reloadStrip { reloadStripContent(); return }

    var configuration = pagingController.tabBar.configuration
    var layout = configuration.layout

    switch stripDataset {
    case .scrollableLong:
      layout.isScrollable = widthDemo != .fillEqually
    case .compactAlignment:
      layout.isScrollable = false
    }

    switch widthDemo {
    case .intrinsic:
      layout.widthMode = .intrinsic
    case .fixed:
      layout.widthMode = .fixed(88)
    case .fillEqually:
      layout.isScrollable = false
      layout.widthMode = .fillEqually
    case .constrained:
      layout.isScrollable = stripDataset == .scrollableLong
      layout.widthMode = .constrained(min: 72, max: 140)
    }

    layout.selectionScrollPosition = Self.scrollPosition(for: scrollDemo)
    layout.contentAlignment = Self.contentAlignment(for: alignmentDemo)
    configuration.layout = layout
    pagingController.tabBar.configuration = configuration

    let alignmentActive = widthDemo != .fillEqually && !layout.isScrollable
    statusLabel.text = """
      Selected @\(pagingController.selectedIndex) · scrollable=\(layout.isScrollable) · \
      contentAlignment \(alignmentActive ? "active" : "ignored (overflow or fillEqually)")
      """
  }

  private func stepSelection(by delta: Int) {
    let next = min(max(0, pagingController.selectedIndex + delta), max(0, pagingController.pageCount - 1))
    pagingController.setSelectedIndex(next, animated: true)
  }

  private static func makeTabs(for dataset: StripDataset) -> [FKTabBarItem] {
    switch dataset {
    case .scrollableLong:
      return FKTabBarExampleSupport.makeLongTitleItems()
    case .compactAlignment:
      return FKTabBarExampleSupport.makeItems(5, localizedTitles: ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"])
    }
  }

  private static func makePages(count: Int) -> [UIViewController] {
    let hues: [CGFloat] = [0.55, 0.12, 0.72, 0.38, 0.08, 0.62, 0.28, 0.48, 0.82, 0.18, 0.52]
    return (0..<count).map { index in
      let hue = hues[index % hues.count]
      let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.94, alpha: 1)
      return FKPagingDemoPageViewController(color: color, titleText: "Page \(index + 1)")
    }
  }

  private static func scrollPosition(for demo: ScrollDemo) -> FKTabBarSelectionScrollPosition {
    switch demo {
    case .minimal: return .minimalVisible
    case .center: return .center
    case .leading: return .leading
    case .trailing: return .trailing
    }
  }

  private static func contentAlignment(for demo: AlignmentDemo) -> FKTabBarContentAlignment {
    switch demo {
    case .leading: return .leading
    case .center: return .center
    case .trailing: return .trailing
    case .spaceBetween: return .spaceBetween
    case .spaceAround: return .spaceAround
    case .spaceEvenly: return .spaceEvenly
    }
  }
}
