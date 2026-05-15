import FKCompositeKit
import UIKit

/// Individual anchored-dropdown + ``FKFilterController`` patterns (English data, ``FKFilterExampleStaticData``).
enum FKFilterDropdownAnchoredDemo: Int, CaseIterable {
  /// Six panel kinds with a scrollable, intrinsic-width tab strip.
  case scrollableSixPanels
  /// Equal tabs: scope · course grid · multi-select tags.
  case equalCommerce
  /// Equal tabs: two-column browse · formats · sort list.
  case equalLibrary
  /// Equal tabs + default crossfade (baseline for comparing other equal-tab tweaks).
  case compactCrossfadeBaseline
  /// Tab changes dismiss then re-present the anchored shell.
  case switchDismissThenPresent
  /// In-place tab switch with vertical slide.
  case switchSlideVertical
  /// Heavier backdrop dimming.
  case backdropStrongDim
  /// Zero-alpha dim + passthrough interaction on the presenter.
  case backdropPassthrough
  /// No per-tab view-controller cache.
  case contentRecreate
  /// Slower ``FKAnchoredDropdownConfiguration/presentationLayoutAnimation`` after height changes.
  case layoutAnimationSlow

  var menuTitle: String {
    switch self {
    case .scrollableSixPanels: return "All panel kinds · scrollable strip"
    case .equalCommerce: return "Equal tabs · scope & catalog & tags"
    case .equalLibrary: return "Equal tabs · browse & formats & sort"
    case .compactCrossfadeBaseline: return "Equal tabs · crossfade baseline"
    case .switchDismissThenPresent: return "Tab switch · dismiss then present"
    case .switchSlideVertical: return "Tab switch · slide vertical"
    case .backdropStrongDim: return "Backdrop · strong dim"
    case .backdropPassthrough: return "Backdrop · passthrough (zero dim)"
    case .contentRecreate: return "Content caching · recreate"
    case .layoutAnimationSlow: return "Layout animation · slow relayout"
    }
  }

  var menuSubtitle: String {
    switch self {
    case .scrollableSixPanels:
      return "Hierarchy, grid, two chip columns, tags, and single list — intrinsic-width tabs."
    case .equalCommerce:
      return "Three equal-width tabs using dual grid, secondary chips, and multi-select tags."
    case .equalLibrary:
      return "Two-column list, primary chip grid, and centered single list."
    case .compactCrossfadeBaseline:
      return "Three compact tabs; default replace-in-place crossfade between panels."
    case .switchDismissThenPresent:
      return "Uses dismiss-then-present when changing tabs while the panel stays open."
    case .switchSlideVertical:
      return "Replace-in-place with a vertical slide between panel contents."
    case .backdropStrongDim:
      return "Higher dim alpha on the anchored presentation backdrop."
    case .backdropPassthrough:
      return "Zero dim + passthrough so taps fall through to the screen behind."
    case .contentRecreate:
      return "contentCachingPolicy .recreate — panels rebuild when re-opened."
    case .layoutAnimationSlow:
      return "Longer presentationLayoutAnimation when preferredContentSize changes."
    }
  }

  var screenTitle: String { menuTitle }

  fileprivate var filterConfiguration: FKFilterConfiguration<String> {
    switch self {
    case .scrollableSixPanels:
      return FKFilterExampleAppearance.makeHubFilterConfiguration()
    case .equalCommerce, .equalLibrary:
      return FKFilterExampleAppearance.makeEqualThreeFilterConfiguration()
    case .compactCrossfadeBaseline:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreeAnchoredConfiguration())
    case .switchDismissThenPresent:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreeDismissThenPresent())
    case .switchSlideVertical:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreeSlideVerticalSwitch())
    case .backdropStrongDim:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreeStrongBackdrop())
    case .backdropPassthrough:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreePassthroughBackdrop())
    case .contentRecreate:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreeRecreateContent())
    case .layoutAnimationSlow:
      return FKFilterExampleAppearance.makeFilterConfiguration(anchored: FKFilterExampleAppearance.equalThreeSlowLayoutAnimation())
    }
  }

  fileprivate var initialState: FKFilterExampleState {
    switch self {
    case .scrollableSixPanels:
      return FKFilterExampleState.presetFullHub()
    case .equalCommerce:
      return FKFilterExampleState.presetEqualBusiness()
    case .equalLibrary:
      return FKFilterExampleState.presetEqualKnowledge()
    case .compactCrossfadeBaseline, .switchDismissThenPresent, .switchSlideVertical, .backdropStrongDim, .backdropPassthrough,
         .contentRecreate, .layoutAnimationSlow:
      return FKFilterExampleState.presetCompactThree()
    }
  }

  /// `tagsTitle` is only read for ``scrollableSixPanels`` (live tab title after clearing tags).
  fileprivate func makeTabs(tagsTitle: @escaping () -> String) -> [FKFilterTab<String>] {
    switch self {
    case .scrollableSixPanels:
      return [
        .init(id: "browse", panelKind: .hierarchy, title: "Browse"),
        .init(id: "catalog", panelKind: .dualHierarchy, title: "Courses"),
        .init(id: "formats", panelKind: .gridPrimary, title: "Formats"),
        .init(id: "scope", panelKind: .gridSecondary, title: "Scope"),
        FKFilterTab(
          id: "tags",
          panelKind: .tags,
          title: tagsTitle,
          subtitle: { "Optional multi-select" },
          allowsMultipleSelection: true
        ),
        .init(id: "sort", panelKind: .singleList, title: "Newest"),
      ]
    case .equalCommerce:
      return [
        .init(id: "scope", panelKind: .gridSecondary, title: "Scope"),
        .init(id: "catalog", panelKind: .dualHierarchy, title: "Catalog"),
        .init(
          id: "tags",
          panelKind: .tags,
          title: "Topics",
          subtitle: "Optional multi-select",
          allowsMultipleSelection: true
        ),
      ]
    case .equalLibrary, .compactCrossfadeBaseline, .switchDismissThenPresent, .switchSlideVertical, .backdropStrongDim,
         .backdropPassthrough, .contentRecreate, .layoutAnimationSlow:
      return [
        .init(id: "browse", panelKind: .hierarchy, title: "Browse"),
        .init(id: "formats", panelKind: .gridPrimary, title: "Formats"),
        .init(id: "sort", panelKind: .singleList, title: "Sort"),
      ]
    }
  }

  fileprivate var usesTagsTitleCallback: Bool {
    switch self {
    case .scrollableSixPanels: return true
    default: return false
    }
  }
}

/// Hosts ``FKFilterController`` for a single ``FKFilterDropdownAnchoredDemo`` pattern.
final class FKFilterDropdownAnchoredPatternViewController: UIViewController {
  private let demo: FKFilterDropdownAnchoredDemo
  private let demoState: FKFilterExampleState
  private let tabStrip = FKFilterExampleTabStripView()
  private var tagsTabTitle = "Topics"
  private var filterHost: FKFilterController<String>!

  init(demo: FKFilterDropdownAnchoredDemo) {
    self.demo = demo
    self.demoState = demo.initialState
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = demo.screenTitle
    view.backgroundColor = .systemBackground

    let panelFactory: FKFilterPanelFactory
    if demo.usesTagsTitleCallback {
      panelFactory = FKFilterExamplePanelFactoryBuilder.makeFactory(
        bindingTo: demoState,
        filterConfiguration: demo.filterConfiguration,
        onTagsSelectionEmptied: { [weak self] in
          guard let self else { return }
          self.tagsTabTitle = "Topics"
          self.filterHost.dropdownController.reloadTabBarItems()
        }
      )
    } else {
      panelFactory = FKFilterExamplePanelFactoryBuilder.makeFactory(
        bindingTo: demoState,
        filterConfiguration: demo.filterConfiguration
      )
    }

    let tabs = demo.makeTabs(tagsTitle: { [weak self] in self?.tagsTabTitle ?? "Topics" })
    filterHost = FKFilterController(
      tabs: tabs,
      panelFactory: panelFactory,
      filterConfiguration: demo.filterConfiguration,
      tabBarHost: tabStrip
    )

    guard let strip = FKFilterExampleChrome.embed(
      filterHost: filterHost,
      in: self,
      topAnchor: view.safeAreaLayoutGuide.topAnchor,
      overlayHost: view,
      logSelection: true
    ) else { return }
    FKFilterExampleChrome.installBodyPlaceholder(below: strip.bottomAnchor, in: self)
    let tabIDs = demo.makeTabs(tagsTitle: { [weak self] in self?.tagsTabTitle ?? "Topics" }).map(\.id)
    tabIDs.forEach { filterHost.invalidateCachedPanelContent(for: $0) }
  }
}
