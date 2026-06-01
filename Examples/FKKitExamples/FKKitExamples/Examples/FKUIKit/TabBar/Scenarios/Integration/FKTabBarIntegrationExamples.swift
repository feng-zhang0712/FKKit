import UIKit
import FKUIKit

// MARK: - DataSource

/// Supplies items through ``FKTabBarDataSource`` instead of manual `reload(items:)`.
final class FKTabBarDataSourceExampleViewController: UIViewController, FKTabBarDataSource, FKTabBarDelegate {
  private var backingItems = FKTabBarExampleSupport.makeItems(4)
  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(items: [], selectedIndex: 0)
    tab.dataSource = self
    tab.delegate = self
    tab.reloadData()
    return tab
  }()

  private let logLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "DataSource"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("FKTabBarDataSource"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "When dataSource is set, reloadData() rebuilds from numberOfItems + itemAt. reload(items:) still updates the manual cache used when dataSource is nil."
      )
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Append tab") { [weak self] in
      self?.appendTab()
    })
    logLabel.font = .preferredFont(forTextStyle: .footnote)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Ready."
    stack.addArrangedSubview(logLabel)

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }

  func tabBar(
    _ tabBar: FKTabBar,
    didReloadItems items: [FKTabBarItem],
    visibleItems: [FKTabBarItem],
    selectedIndex: Int
  ) {
    logLabel.text = "didReloadItems visible=\(visibleItems.count) selected=\(selectedIndex)"
  }

  func numberOfItems(in tabBar: FKTabBar) -> Int {
    backingItems.count
  }

  func tabBar(_ tabBar: FKTabBar, itemAt index: Int) -> FKTabBarItem {
    backingItems[index]
  }

  private func appendTab() {
    let index = backingItems.count
    backingItems.append(
      FKTabBarItem(
        id: "ds-\(index)",
        title: .init(normal: .init(text: "Tab \(index)")),
        image: .init(normal: .init(source: .systemSymbol(name: "star")))
      )
    )
    tabView.reloadData(updatePolicy: .preserveSelection)
  }
}

// MARK: - Non-scrollable overflow

/// Compares ``FKTabBarNonScrollableOverflowPolicy`` when tabs do not scroll and prints ``resolvedLayoutHintsForCurrentEnvironment()``.
final class FKTabBarNonScrollableOverflowExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(
    layout: .init(
      isScrollable: false,
      titleOverflowMode: .truncate,
      widthMode: .fillEqually
    )
  )
  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeLongTitleItems().prefix(4).map { $0 },
    selectedIndex: 0,
    configuration: configuration
  )
  private let hintsLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Overflow policy"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("nonScrollableOverflowPolicy"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "When isScrollable is false, shrink / truncate / clip controls long titles in equal-width slots. Clip and truncate share the same title layout; clip also sets collectionView.clipsToBounds."
      )
    )

    let control = UISegmentedControl(items: ["Shrink", "Truncate", "Clip"])
    control.selectedSegmentIndex = 0
    control.addAction(UIAction { [weak self] action in
      guard let self, let segment = action.sender as? UISegmentedControl else { return }
      switch segment.selectedSegmentIndex {
      case 1: self.configuration.layout.nonScrollableOverflowPolicy = .truncate
      case 2: self.configuration.layout.nonScrollableOverflowPolicy = .clip
      default: self.configuration.layout.nonScrollableOverflowPolicy = .shrink
      }
      self.tabView.applyConfiguration(self.configuration, animated: false)
      self.refreshHints()
    }, for: .valueChanged)
    stack.addArrangedSubview(control)

    hintsLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    hintsLabel.textColor = .secondaryLabel
    hintsLabel.numberOfLines = 0
    stack.addArrangedSubview(hintsLabel)

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
    refreshHints()
  }

  private func refreshHints() {
    let hints = tabView.resolvedLayoutHintsForCurrentEnvironment()
    hintsLabel.text = """
    resolved overflow=\(hints.titlePresentation.overflowMode)
    lines=\(hints.titlePresentation.maximumTitleLines)
    growHeight=\(hints.titlePresentation.shouldIncreaseBarHeight)
    contentAlignmentActive=\(hints.isContentAlignmentActive)
    """
  }
}

// MARK: - Empty state

/// Shows ``FKTabBarLayoutConfiguration/emptyStateMessage`` when the visible strip is empty.
final class FKTabBarEmptyStateExampleViewController: UIViewController {
  private var items = FKTabBarExampleSupport.makeItems(3)
  private lazy var tabView = FKTabBar(items: items, selectedIndex: 0)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Empty state"
    view.backgroundColor = .systemBackground

    var configuration = tabView.configuration
    configuration.layout.emptyStateMessage = "No tabs available"
    tabView.configuration = configuration

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("emptyStateMessage"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Set layout.emptyStateMessage to show a centered placeholder when every item is hidden or removed."
      )
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Clear all tabs") { [weak self] in
      self?.clearTabs()
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Restore tabs") { [weak self] in
      self?.restoreTabs()
    })

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
  }

  private func clearTabs() {
    tabView.reload(items: [], updatePolicy: .resetSelection)
  }

  private func restoreTabs() {
    tabView.reload(items: items, updatePolicy: .preserveSelection)
  }
}

// MARK: - Selection observability

/// Logs ``FKTabBar/selectionSnapshot``, ``FKTabBar/onSelectionProgress``, and ``FKTabBar/selectedItemID``.
final class FKTabBarSelectionObservabilityExampleViewController: UIViewController {
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(5), selectedIndex: 1)
  private let logView = UITextView()
  private let slider = UISlider()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Selection telemetry"
    view.backgroundColor = .systemBackground

    tabView.onSelectionProgress = { [weak self] from, to, progress in
      self?.appendLog(String(format: "onSelectionProgress %.2f  %d → %d", progress, from, to))
    }
    tabView.onSelectionChanged = { [weak self] item, index, reason in
      self?.logSnapshot(prefix: "didSelect @\(index) (\(item.id)) reason=\(reason)")
    }

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("selectionSnapshot + onSelectionProgress"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Drive progress from an external pager or the slider below. selectedItemID stays stable across reloads when IDs are preserved."
      )
    )

    slider.minimumValue = 0
    slider.maximumValue = 1
    slider.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISlider else { return }
      self.tabView.setSelectionProgress(from: 1, to: 2, progress: CGFloat(control.value))
    }, for: .valueChanged)
    stack.addArrangedSubview(slider)

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logView.heightAnchor.constraint(equalToConstant: 140).isActive = true
    stack.addArrangedSubview(logView)

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view)
    logSnapshot(prefix: "Ready")
  }

  private func logSnapshot(prefix: String) {
    let snap = tabView.selectionSnapshot
    appendLog("\(prefix) | phase=\(snap.phase) index=\(snap.selectedIndex) id=\(tabView.selectedItemID ?? "nil")")
  }

  private func appendLog(_ line: String) {
    logView.text = (logView.text ?? "") + line + "\n"
  }
}

// MARK: - Anchor button

/// Resolves ``FKTabBar/visibleItemButton(at:)`` for popover / menu anchoring.
final class FKTabBarVisibleItemButtonExampleViewController: UIViewController {
  private lazy var tabView = FKTabBar(
    items: [
      FKTabBarItem(id: "all", title: .init(normal: .init(text: "All"))),
      FKTabBarItem(id: "price", title: .init(normal: .init(text: "Price")), accessoryIcon: .systemSymbol("chevron.down")),
      FKTabBarItem(id: "brand", title: .init(normal: .init(text: "Brand")), accessoryIcon: .systemSymbol("chevron.down")),
    ],
    selectedIndex: 0,
    configuration: FKTabBarPresets.filterStrip()
  )
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Anchor button"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("visibleItemButton(at:)"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Use the returned FKButton as an anchor for FKCallout, UIMenu, or UIActivityViewController. Tap Resolve to highlight the button for the selected index."
      )
    )

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    stack.addArrangedSubview(statusLabel)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Resolve anchor for selected tab") { [weak self] in
      self?.resolveAnchor()
    })

    tabView.onSelectionChanged = { [weak self] _, index, _ in
      self?.statusLabel.text = "Selected visible index: \(index)"
    }

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 48)
    statusLabel.text = "Selected visible index: 0"
  }

  private func resolveAnchor() {
    let index = tabView.selectedIndex
    guard let button = tabView.visibleItemButton(at: index) else {
      statusLabel.text = "No FKButton at index \(index)"
      return
    }
    button.layer.borderWidth = 2
    button.layer.borderColor = UIColor.systemOrange.cgColor
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak button] in
      button?.layer.borderWidth = 0
    }
    statusLabel.text = "Anchor resolved: FKButton for visible index \(index) — frame \(button.frame.integral)"
  }
}

#if canImport(SwiftUI)
import SwiftUI

/// Hosts ``FKTabBarRepresentable`` with controlled selection, progress callback, and progress binding modes.
final class FKTabBarSwiftUIExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemBackground

    let host = UIHostingController(rootView: FKTabBarSwiftUIHubView())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    host.didMove(toParent: self)

    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

private enum FKTabBarSwiftUIDemoMode: String, CaseIterable, Identifiable {
  case controlledSelection
  case progressBinding

  var id: String { rawValue }

  var title: String {
    switch self {
    case .controlledSelection: return "Controlled selection"
    case .progressBinding: return "Progress binding"
    }
  }
}

private struct FKTabBarSwiftUIHubView: View {
  @State private var mode = FKTabBarSwiftUIDemoMode.controlledSelection

  var body: some View {
    VStack(spacing: 12) {
      Picker("Demo", selection: $mode) {
        ForEach(FKTabBarSwiftUIDemoMode.allCases) { item in
          Text(item.title).tag(item)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)

      switch mode {
      case .controlledSelection:
        FKTabBarSwiftUIControlledDemoView()
      case .progressBinding:
        FKTabBarSwiftUIProgressBindingDemoView()
      }
    }
    .padding(.top, 8)
  }
}

private struct FKTabBarSwiftUIControlledDemoView: View {
  @State private var selectedIndex = 1
  @State private var log = "Ready — controlled mode: tap a tab to request selection."

  private let items = FKTabBarExampleSupport.makeItems(4)

  var body: some View {
    VStack(spacing: 12) {
      FKTabBarRepresentable(
        items: items,
        selectedIndex: $selectedIndex,
        configuration: FKTabBarPresets.pagerHeader(),
        selectionControlMode: .controlled,
        onSelectionRequest: { item, index in
          log = "onSelectionRequest @\(index) (\(item.id)) — committing"
          selectedIndex = index
        },
        onSelectionProgress: { from, to, progress in
          log = String(format: "onSelectionProgress %.2f  %d → %d", progress, from, to)
        }
      )
      .frame(height: 52)

      Text("selectedIndex = \(selectedIndex)")
        .font(.footnote.monospacedDigit())
      Text(log)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
  }
}

private struct FKTabBarSwiftUIProgressBindingDemoView: View {
  @State private var selectedIndex = 0
  @State private var selectionProgress: FKTabBarSelectionProgress?
  @State private var log = "Drag the slider to drive selectionProgress binding."

  private let items = FKTabBarExampleSupport.makeItems(5)

  var body: some View {
    VStack(spacing: 12) {
      FKTabBarRepresentable(
        items: items,
        selectedIndex: $selectedIndex,
        selectionProgress: $selectionProgress,
        configuration: FKTabBarPresets.pagerHeader(),
        onSelectionProgress: { from, to, progress in
          log = String(format: "callback %.2f  %d → %d", progress, from, to)
        }
      )
      .frame(height: 52)

      Slider(value: Binding(
        get: { Double(selectionProgress?.progress ?? 0) },
        set: { newValue in
          let from = selectedIndex
          let to = min(items.count - 1, from + 1)
          selectionProgress = FKTabBarSelectionProgress(fromIndex: from, toIndex: to, progress: CGFloat(newValue))
        }
      ))

      Text("selectedIndex = \(selectedIndex)")
        .font(.footnote.monospacedDigit())
      if let selectionProgress {
        Text(String(format: "binding progress %.2f  %d → %d", selectionProgress.progress, selectionProgress.fromIndex, selectionProgress.toIndex))
          .font(.footnote.monospacedDigit())
      }
      Text(log)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    .padding(.horizontal)
  }
}
#endif
