import UIKit
import FKUIKit

fileprivate struct ExampleMenuItem {
  let title: String
  let subtitle: String
  let make: () -> UIViewController
}

fileprivate struct KitEntry {
  let title: String
  let subtitle: String
  let items: [ExampleMenuItem]
}

/// Two-level example index:
/// - Level 1: two target entries (`FKUIKit`, `FKCoreKit`)
/// - Level 2: examples under the selected target
final class ExampleMenuViewController: UITableViewController {

  private static let kitEntries: [KitEntry] = [
    KitEntry(
      title: "FKUIKit",
      subtitle: "Foundational UI components and presentation infrastructure",
      items: [
        ExampleMenuItem(
          title: "ActionSheet",
          subtitle: "Hub: basics, appearance, selection, custom rows, toggle, lifecycle, live updates, presentation, builder, SwiftUI",
          make: { FKActionSheetExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Badge",
          subtitle: "Dot, numeric & text badges, anchors, animations, TabBarItem",
          make: { FKBadgeExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "BlurView",
          subtitle: "High-performance blur view examples (UIKit / SwiftUI / IB)",
          make: { FKBlurViewExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Button",
          subtitle: "Basics, layout, interaction, appearance, loading, global style & IB",
          make: { FKButtonExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Callout",
          subtitle: "Hub: FKTooltip, FKPopover, placements, menus, coach mark, FKCallout builder",
          make: { FKCalloutExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Carousel",
          subtitle: "Hub: FKImageBanner heroes, FKCarousel layouts, indicators, auto-scroll, SwiftUI, RTL",
          make: { FKCarouselExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "CornerShadow",
          subtitle: "Any-corner radius + high-performance shadow (path based)",
          make: { FKCornerShadowExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Divider",
          subtitle: "Hub: basics, line styles, edge pinning, defaults, SwiftUI",
          make: { FKDividerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "EmptyState",
          subtitle: "Hub: basics (empty/error/offline) and advanced (i18n, resolver, RTL)",
          make: { FKEmptyStateExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "ExpandableText",
          subtitle: "Hub: UILabel / UITextView / SwiftUI (shared support + Examples/)",
          make: { FKExpandableTextExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "FlowVisualization",
          subtitle: "Hub: FKStepIndicator & FKTimeline — checkout, logistics, layouts, states, SwiftUI, RTL",
          make: { FKFlowVisualizationExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "VideoPlayer",
          subtitle: "Hub: VOD/HLS/live, playlist, subtitles, feed pool, offline, ads, QoE, SwiftUI",
          make: { FKVideoPlayerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "AudioPlayer",
          subtitle: "Hub: MP3/HLS, queue modes, lyrics, mini bar, sleep timer, history, QoE, SwiftUI",
          make: { FKAudioPlayerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "ImageView",
          subtitle: "Hub: FKImageView (profiles, placeholders, chrome, reuse, SwiftUI) + FKImageLoader",
          make: { FKImageViewExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "PhotoPicker",
          subtitle: "Hub: library/camera pick, presets, multi-select, delivery, video, permissions, SwiftUI",
          make: { FKPhotoPickerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "PagingController",
          subtitle: "FKTabBar ↔ UIPageViewController sync: lazy/SwiftUI/delegate, RTL & gestures (Public/Internal/Extension)",
          make: { FKPagingControllerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "SearchBar",
          subtitle: "Hub: FKSearchBar & FKSearchField — debounce, nav/inline, loading, cancel, table+empty, SwiftUI",
          make: { FKSearchExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "SheetPresentationController",
          subtitle: "Custom SheetPresentationController examples (sheet/center/anchor, animation, backdrop, keyboard, rotation)",
          make: { FKSheetPresentationControllerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "ProgressBar",
          subtitle: "Hub: interactive playground, preset gallery, delegate log, SwiftUI bridge, RTL & accessibility",
          make: { FKProgressBarExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "RatingControl",
          subtitle: "Hub: interactive/read-only stars, icon presets, playground, delegate, SwiftUI, RTL & a11y",
          make: { FKRatingControlExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Refresh",
          subtitle: "Hub: default, GIF, hosted, delegate, settings, collection, scroll view, …",
          make: { FKRefreshExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Skeleton",
          subtitle: "Hub: overlay, auto, presets, container, lists, manager, global defaults",
          make: { FKSkeletonExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "TabBar",
          subtitle: "Segmented tab bar with indicators, dynamic data, width policies, and a11y/i18n examples",
          make: { FKTabBarExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "TextField",
          subtitle: "Formatted input, validation, style customization, callbacks, and global defaults",
          make: { FKTextFieldExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Toast",
          subtitle: "Global Toast/HUD/Snackbar hints with queueing, styles, positions, custom view, and SwiftUI support",
          make: { FKToastExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "WebView",
          subtitle: "Hub: HTTPS load, chrome, progress, errors, policy, JS bridge, OAuth, SwiftUI, sheet, ephemeral store",
          make: { FKWebViewExamplesHubViewController() }
        ),
      ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    ),
    KitEntry(
      title: "FKCoreKit",
      subtitle: "Core non-UI capabilities (networking, logging, utilities, etc.)",
      items: [
        ExampleMenuItem(
          title: "Async",
          subtitle: "Main/background dispatch, delay cancel, debounce, throttle, groups, executors",
          make: { FKAsyncExampleViewController() }
        ),
        ExampleMenuItem(
          title: "BiometricAuth",
          subtitle: "Hub: capability, policies, reuse window, cancellation, mock, Keychain unlock pattern",
          make: { FKBiometricAuthExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "BusinessKit",
          subtitle: "Version, tracking, i18n, lifecycle, deeplink, device info, business utils",
          make: { FKBusinessKitExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FileManager",
          subtitle: "Sandbox/file ops, read/write, resumable download, upload, cache and ZIP APIs",
          make: { FKFileManagerExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKI18n",
          subtitle: "Language switching, bundle lookup, format variables, dictionary backend, observers, RTL, integration",
          make: { FKI18nExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Logger",
          subtitle: "5-level logs, config, file persistence, crash capture, export/clear",
          make: { FKLoggerExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Network",
          subtitle: "GET/POST, async/await, upload/download, cache, cancel, parsing",
          make: { FKNetworkExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Permissions",
          subtitle: "Unified permission status/query/request, batch, denied handling, settings jump",
          make: { FKPermissionsExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Pluggable",
          subtitle: "Protocol contracts: networking, analytics, storage, session, routing, UIKit cells",
          make: { FKPluggableExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Security",
          subtitle: "Hash, AES, RSA, Base64/HEX/URL, HMAC, random, masking, wipe, anti-debug",
          make: { FKSecurityExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Storage",
          subtitle: "UserDefaults, Keychain, file, memory cache, TTL, purge, async",
          make: { FKStorageExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Extension",
          subtitle: "fk_* helpers for Foundation, UIKit, device info, validation, and formatting",
          make: { FKExtensionExampleViewController() }
        ),
      ]
    ),
  ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKKit Examples"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Self.kitEntries.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let entry = Self.kitEntries[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = entry.title
    config.secondaryText = entry.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let entry = Self.kitEntries[indexPath.row]
    let vc = KitExamplesViewController(title: entry.title, items: entry.items)
    navigationController?.pushViewController(vc, animated: true)
  }
}

private final class KitExamplesViewController: UITableViewController {
  private let screenTitle: String
  private let items: [ExampleMenuItem]

  init(title: String, items: [ExampleMenuItem]) {
    self.screenTitle = title
    self.items = items.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = screenTitle
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = items[indexPath.row].make()
    navigationController?.pushViewController(vc, animated: true)
  }
}
