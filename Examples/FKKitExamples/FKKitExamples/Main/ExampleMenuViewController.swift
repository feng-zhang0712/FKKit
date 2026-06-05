import UIKit
import FKCoreKit
import FKUIKit

fileprivate struct ExampleMenuItem {
  let titleKey: String
  let subtitleKey: String
  let make: () -> UIViewController

  var title: String { FKExamplesI18n.string(titleKey) }
  var subtitle: String { FKExamplesI18n.string(subtitleKey) }
}

fileprivate struct KitEntry {
  let titleKey: String
  let subtitleKey: String
  let items: [ExampleMenuItem]

  var title: String { FKExamplesI18n.string(titleKey) }
  var subtitle: String { FKExamplesI18n.string(subtitleKey) }
}

/// Two-level example index:
/// - Level 1: two target entries (`FKUIKit`, `FKCoreKit`)
/// - Level 2: examples under the selected target
final class ExampleMenuViewController: UITableViewController {

  private var observationToken: FKI18nObservationToken?

  private static let kitEntries: [KitEntry] = [
    KitEntry(
      titleKey: "examples.menu.kit.fkuikit.title",
      subtitleKey: "examples.menu.kit.fkuikit.subtitle",
      items: [
        ExampleMenuItem(
          titleKey: "examples.menu.item.actionsheet.title",
          subtitleKey: "examples.menu.item.actionsheet.subtitle",
          make: { FKActionSheetExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.badge.title",
          subtitleKey: "examples.menu.item.badge.subtitle",
          make: { FKBadgeExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.blurview.title",
          subtitleKey: "examples.menu.item.blurview.subtitle",
          make: { FKBlurViewExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.button.title",
          subtitleKey: "examples.menu.item.button.subtitle",
          make: { FKButtonExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.callout.title",
          subtitleKey: "examples.menu.item.callout.subtitle",
          make: { FKCalloutExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.cornershadow.title",
          subtitleKey: "examples.menu.item.cornershadow.subtitle",
          make: { FKCornerShadowExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.divider.title",
          subtitleKey: "examples.menu.item.divider.subtitle",
          make: { FKDividerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.emptystate.title",
          subtitleKey: "examples.menu.item.emptystate.subtitle",
          make: { FKEmptyStateExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.expandabletext.title",
          subtitleKey: "examples.menu.item.expandabletext.subtitle",
          make: { FKExpandableTextExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.videoplayer.title",
          subtitleKey: "examples.menu.item.videoplayer.subtitle",
          make: { FKVideoPlayerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.audioplayer.title",
          subtitleKey: "examples.menu.item.audioplayer.subtitle",
          make: { FKAudioPlayerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.pagingcontroller.title",
          subtitleKey: "examples.menu.item.pagingcontroller.subtitle",
          make: { FKPagingControllerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.sheetpresentationcontroller.title",
          subtitleKey: "examples.menu.item.sheetpresentationcontroller.subtitle",
          make: { FKSheetPresentationControllerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.progressbar.title",
          subtitleKey: "examples.menu.item.progressbar.subtitle",
          make: { FKProgressBarExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.ratingcontrol.title",
          subtitleKey: "examples.menu.item.ratingcontrol.subtitle",
          make: { FKRatingControlExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.refresh.title",
          subtitleKey: "examples.menu.item.refresh.subtitle",
          make: { FKRefreshExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.skeleton.title",
          subtitleKey: "examples.menu.item.skeleton.subtitle",
          make: { FKSkeletonExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.tabbar.title",
          subtitleKey: "examples.menu.item.tabbar.subtitle",
          make: { FKTabBarExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.textfield.title",
          subtitleKey: "examples.menu.item.textfield.subtitle",
          make: { FKTextFieldExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.toast.title",
          subtitleKey: "examples.menu.item.toast.subtitle",
          make: { FKToastExamplesHubViewController() }
        ),
      ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    ),
    KitEntry(
      titleKey: "examples.menu.kit.fkcorekit.title",
      subtitleKey: "examples.menu.kit.fkcorekit.subtitle",
      items: [
        ExampleMenuItem(
          titleKey: "examples.menu.item.async.title",
          subtitleKey: "examples.menu.item.async.subtitle",
          make: { FKAsyncExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.businesskit.title",
          subtitleKey: "examples.menu.item.businesskit.subtitle",
          make: { FKBusinessKitExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.filemanager.title",
          subtitleKey: "examples.menu.item.filemanager.subtitle",
          make: { FKFileManagerExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.i18n.title",
          subtitleKey: "examples.menu.item.i18n.subtitle",
          make: { FKI18nExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.logger.title",
          subtitleKey: "examples.menu.item.logger.subtitle",
          make: { FKLoggerExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.network.title",
          subtitleKey: "examples.menu.item.network.subtitle",
          make: { FKNetworkExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.permissions.title",
          subtitleKey: "examples.menu.item.permissions.subtitle",
          make: { FKPermissionsExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.pluggable.title",
          subtitleKey: "examples.menu.item.pluggable.subtitle",
          make: { FKPluggableExamplesHubViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.security.title",
          subtitleKey: "examples.menu.item.security.subtitle",
          make: { FKSecurityExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.storage.title",
          subtitleKey: "examples.menu.item.storage.subtitle",
          make: { FKStorageExampleViewController() }
        ),
        ExampleMenuItem(
          titleKey: "examples.menu.item.utils.title",
          subtitleKey: "examples.menu.item.utils.subtitle",
          make: { FKUtilsExampleViewController() }
        ),
      ]
    ),
  ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    reloadLocalizedContent()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    observationToken = FKI18nManager.shared.observeLanguageChange { [weak self] _ in
      Task { @MainActor in
        self?.reloadLocalizedContent()
      }
    }
  }

  private func reloadLocalizedContent() {
    title = FKExamplesI18n.string("examples.app.title")
    tableView.reloadData()
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
  private var observationToken: FKI18nObservationToken?

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
    observationToken = FKI18nManager.shared.observeLanguageChange { [weak self] _ in
      Task { @MainActor in
        self?.tableView.reloadData()
      }
    }
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
