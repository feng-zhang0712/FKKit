import UIKit

final class FKTabBarExamplesHubViewController: UITableViewController {
  // MARK: - Navigation shell (TabBar)
  //
  // This hub is intentionally a lightweight navigation shell for open-source users.
  // Each destination page demonstrates one capability area and how to integrate FKTabBar as a UIView.
  //
  // Important boundaries:
  // - FKTabBar does NOT manage controllers, navigation, or paging containers.
  // - Example pages may simulate "paging progress" via slider, but FKTabBar only renders UI and interpolation.
  private struct SectionModel {
    let title: String
    let rows: [RowModel]
  }

  private struct RowModel {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let sections: [SectionModel] = [
    SectionModel(
      title: "Basic",
      rows: [
        RowModel(
          title: "Basic playground (recommended)",
          subtitle: "One page: fixedEqual vs scrollable, enabled=false, programmatic select notify, and reload(items:).",
          make: { FKTabBarBasicPlaygroundExampleViewController() }
        ),
        RowModel(
          title: "Basic — content types",
          subtitle: "Text/symbol/image/custom content + intrinsicWidthMeasurement toggle (normalStateOnly vs adjustsOnSelection).",
          make: { FKTabBarContentTypesExampleViewController() }
        ),
        RowModel(
          title: "Basic — filter strip preset",
          subtitle: "filterStrip preset, per-tab trailing icon animations, expandedItemID, pending selection.",
          make: { FKTabBarFilterStripExampleViewController() }
        ),
        RowModel(
          title: "Basic — presets",
          subtitle: "Compare pagerHeader, segmentedControl, filterStrip, and bottomDocked factories.",
          make: { FKTabBarPresetsExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Layout & insets",
      rows: [
        RowModel(
          title: "Layout — itemInsets",
          subtitle: "Single per-tab padding knob; pairs with indicator trackContentFrame.",
          make: { FKTabBarItemInsetsExampleViewController() }
        ),
        RowModel(
          title: "Layout — content alignment",
          subtitle: "Non-scrollable strip: leading, center, trailing when items fit without scrolling.",
          make: { FKTabBarContentAlignmentExampleViewController() }
        ),
        RowModel(
          title: "Layout — scroll edge fade",
          subtitle: "Toggle scrollEdgeFade width and enabled state on a scrollable strip.",
          make: { FKTabBarScrollEdgeFadeExampleViewController() }
        ),
        RowModel(
          title: "Layout — custom spacing",
          subtitle: "customSpacing(after:) with per-index gaps via internal flow layout.",
          make: { FKTabBarCustomSpacingExampleViewController() }
        ),
        RowModel(
          title: "Layout — global subtitle",
          subtitle: "appearance.subtitleConfiguration fallback when item.subtitle is nil.",
          make: { FKTabBarGlobalSubtitleExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Scrollable",
      rows: [
        RowModel(
          title: "Scrollable — 10+ tabs",
          subtitle: "Intrinsic widths + horizontal scrolling + auto-scroll to keep selection visible.",
          make: { FKTabBarScrollableManyTabsExampleViewController() }
        ),
        RowModel(
          title: "Scrollable — overflow strategies",
          subtitle: "Compares truncate/shrink/auto/fixed for long titles (Dynamic Type friendly).",
          make: { FKTabBarLongTitleStrategyExampleViewController() }
        ),
        RowModel(
          title: "Scrollable — width & alignment matrix",
          subtitle: "Scroll target: minimal/center/leading/trailing + width strategies.",
          make: { FKTabBarScrollAndWidthStrategyExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Indicator",
      rows: [
        RowModel(
          title: "Indicator — styles & animation",
          subtitle: "Switch indicator styles and animation strategies; stress-tap to verify stability.",
          make: { FKTabBarIndicatorAnimationExampleViewController() }
        ),
        RowModel(
          title: "Indicator — advanced customization",
          subtitle: "indicatorZOrder, indicatorFollowMode, renderCustomIndicator, customIndicatorFrame.",
          make: { FKTabBarIndicatorAdvancedExampleViewController() }
        ),
        RowModel(
          title: "Indicator — paging progress (slider)",
          subtitle: "Drives setSelectionProgress(from:to:progress:) to simulate external pager scroll.",
          make: { FKTabBarPagingProgressExampleViewController() }
        ),
        RowModel(
          title: "Indicator — Reduce Motion",
          subtitle: "Shows animation downgrade behavior when Reduce Motion is enabled.",
          make: { FKTabBarReduceMotionExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Badge",
      rows: [
        RowModel(
          title: "Badge — anchors & rotation",
          subtitle: "Verifies FKBadge mapping, anchors, offsets, and rotation stability.",
          make: { FKTabBarBadgeAnchorAndLandscapeExampleViewController() }
        ),
        RowModel(
          title: "Badge — dynamic updates (99+)",
          subtitle: "Shows dot/number/none/custom and local badge updates without full reload.",
          make: { FKTabBarBadgeUpdatesExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Replace UITabBar",
      rows: [
        RowModel(
          title: "Bottom-docked bar",
          subtitle: "Pins FKTabBar to bottom and compares safe-area height policy, blur/solid background, divider & shadow.",
          make: { FKTabBarReplaceUITabBarExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "RTL / Dynamic Type / Accessibility",
      rows: [
        RowModel(
          title: "RTL — layout direction + mirroring",
          subtitle: "Scrollable strip, itemLayoutDirection, rtlBehavior, semantic RTL, and auto-scroll checklist.",
          make: { FKTabBarRTLExampleViewController() }
        ),
        RowModel(
          title: "Dynamic Type — large text strategies",
          subtitle: "Switches largeTextLayoutStrategy (truncate/shrink/wrap/wrap+height) for accessibility categories.",
          make: { FKTabBarDynamicTypeExampleViewController() }
        ),
        RowModel(
          title: "Accessibility — VoiceOver checklist",
          subtitle: "Validates selected/disabled/badge announcements using per-item state and local badge updates.",
          make: { FKTabBarAccessibilityExampleViewController() }
        ),
        RowModel(
          title: "i18n titles",
          subtitle: "Localized tab titles for string measurement and layout verification.",
          make: { FKTabBarI18nA11yExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Integration",
      rows: {
        var rows = [
          RowModel(
            title: "Integration — customization hooks",
            subtitle: "animateInteraction, trailing icon accessory, shouldSelect closure, badgeConfiguration, badgeAnimation.",
            make: { FKTabBarCustomizationHooksExampleViewController() }
          ),
          RowModel(
            title: "Integration — performBatchUpdates",
            subtitle: "Single layout pass for configuration + badge changes.",
            make: { FKTabBarBatchUpdatesExampleViewController() }
          ),
          RowModel(
            title: "Integration — stable ID APIs",
            subtitle: "setSelectedIndex(forItemID:), setBadge(forItemID:), setItem(forItemID:), reapplyVisibleItemConfigurations().",
            make: { FKTabBarStableIDExampleViewController() }
          ),
          RowModel(
            title: "Integration — long press",
            subtitle: "isLongPressEnabled, onLongPress, resolvedTitlePresentationForCurrentEnvironment().",
            make: { FKTabBarLongPressExampleViewController() }
          ),
          RowModel(
            title: "Integration — custom badge",
            subtitle: "FKTabBarBadgeContent.custom + customBadgeView(for:).",
            make: { FKTabBarCustomBadgeExampleViewController() }
          ),
          RowModel(
            title: "Integration — DataSource",
            subtitle: "Dynamic item supply via FKTabBarDataSource + reloadData().",
            make: { FKTabBarDataSourceExampleViewController() }
          ),
          RowModel(
            title: "Integration — non-scrollable overflow",
            subtitle: "Shrink / truncate / clip + resolvedLayoutHintsForCurrentEnvironment() snapshot.",
            make: { FKTabBarNonScrollableOverflowExampleViewController() }
          ),
          RowModel(
            title: "Integration — empty state",
            subtitle: "layout.emptyStateMessage placeholder when the visible strip is empty.",
            make: { FKTabBarEmptyStateExampleViewController() }
          ),
          RowModel(
            title: "Integration — selection telemetry",
            subtitle: "selectionSnapshot, selectedItemID, and onSelectionProgress logging.",
            make: { FKTabBarSelectionObservabilityExampleViewController() }
          ),
          RowModel(
            title: "Integration — anchor button",
            subtitle: "visibleItemButton(at:) for callout / menu anchoring.",
            make: { FKTabBarVisibleItemButtonExampleViewController() }
          ),
        ]
        #if canImport(SwiftUI)
        rows.append(
          RowModel(
            title: "Integration — SwiftUI representable",
            subtitle: "FKTabBarRepresentable — controlled mode, progress callback, and progress Binding.",
            make: { FKTabBarSwiftUIExampleViewController() }
          )
        )
        #endif
        return rows
      }()
    ),
    SectionModel(
      title: "Performance",
      rows: [
        RowModel(
          title: "Many items + frequent updates",
          subtitle: "Generates 50/100/200 tabs and performs frequent local badge updates to avoid reloadData().",
          make: { FKTabBarPerformanceExampleViewController() }
        ),
      ]
    ),
    SectionModel(
      title: "Dynamic data",
      rows: [
        RowModel(
          title: "Add/remove tabs at runtime",
          subtitle: "Preserve/reset/nearestAvailable policies and hidden item handling.",
          make: { FKTabBarDynamicDataExampleViewController() }
        ),
        RowModel(
          title: "applyChanges + ID diff reload",
          subtitle: "Batch insert/delete/move/update via applyChanges; reload(items:) with preserveSelection.",
          make: { FKTabBarApplyChangesExampleViewController() }
        ),
        RowModel(
          title: "FKUIKit reuse (blur theme)",
          subtitle: "Reuses FKBlurView and shared appearance tokens.",
          make: { FKTabBarFKUIKitReuseExampleViewController() }
        ),
      ]
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TabBar"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}

