import UIKit

/// Image loading stack demos: ``FKImageView`` (FKUIKit) and ``FKImageLoader`` (FKCoreKit).
final class FKImageViewExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "FKImageView · Basics",
      rows: [
        Row(
          title: "Remote URL",
          subtitle: "Default load, placeholder, success transition, onStateChange",
          make: { FKImageViewExampleBasicsViewController() }
        ),
        Row(
          title: "Placeholder variants",
          subtitle: "UIImage, color, SF Symbol, initials, custom UIView provider",
          make: { FKImageViewExamplePlaceholdersViewController() }
        ),
        Row(
          title: "Local setImage",
          subtitle: "Display a bitmap without URL binding or network I/O",
          make: { FKImageViewExampleSetImageViewController() }
        ),
        Row(
          title: "Manual load control",
          subtitle: "loadsAutomatically = false · startLoading() · cancelLoad() · reload()",
          make: { FKImageViewExampleManualLoadViewController() }
        ),
        Row(
          title: "Local file URL",
          subtitle: "file:// source via FKImageView.load(url:)",
          make: { FKImageViewExampleLocalFileViewController() }
        ),
      ]
    ),
    Section(
      title: "FKImageView · Appearance & loading",
      rows: [
        Row(
          title: "Corner, border & shadow",
          subtitle: "FKImageViewCornerStyle · FKLayerBorderStyle · FKLayerShadowStyle",
          make: { FKImageViewExampleAppearanceViewController() }
        ),
        Row(
          title: "Loading chrome",
          subtitle: "Activity indicator · FKProgressBar strip · FKSkeleton overlay",
          make: { FKImageViewExampleLoadingChromeViewController() }
        ),
        Row(
          title: "Failure & retry",
          subtitle: "HTTP 404, offline stub loader, tap-to-retry vs retry button",
          make: { FKImageViewExampleFailureRetryViewController() }
        ),
        Row(
          title: "Interaction & accessibility",
          subtitle: "onTap · highlightOnPress · isDecorative · announcesLayoutChangeOnSuccess",
          make: { FKImageViewExampleInteractionViewController() }
        ),
      ]
    ),
    Section(
      title: "FKImageView · Lists & integration",
      rows: [
        Row(
          title: "Fast-scroll reuse",
          subtitle: "UITableView · FKImageViewProfile.listCell · resetForReuse()",
          make: { FKImageViewExampleListReuseViewController() }
        ),
        Row(
          title: "Profile hierarchy",
          subtitle: "full vs listCell vs minimal · subtree counts · lazy chrome/failure",
          make: { FKImageViewExampleProfileHierarchyViewController() }
        ),
        Row(
          title: "Prefetch pairing",
          subtitle: "FKImageLoader.prefetch · cancelPrefetch · FKImageView cells",
          make: { FKImageViewExamplePrefetchViewController() }
        ),
        Row(
          title: "Custom loader injection",
          subtitle: "imageLoader property · FKImageLoading stub · FKImageViewDefaults",
          make: { FKImageViewExampleCustomLoaderViewController() }
        ),
        Row(
          title: "Cache key override",
          subtitle: "FKImageView.cacheKey · resolvedCacheKey · per-avatar bucket",
          make: { FKImageViewExampleCacheKeyViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "FKImageViewRepresentable · url · configuration · onStateChange",
          make: { FKImageViewExampleSwiftUIViewController() }
        ),
      ]
    ),
    Section(
      title: "FKImageLoader · Programmatic API",
      rows: [
        Row(
          title: "Async load & result",
          subtitle: "loadImage · loadImageResult · returnsSourceData · cancellation",
          make: { FKImageLoaderExampleProgrammaticViewController() }
        ),
        Row(
          title: "Cache policies",
          subtitle: "default · reloadIgnoringCache · cacheOnly · excludesFromDiskCache",
          make: { FKImageLoaderExampleCachePolicyViewController() }
        ),
        Row(
          title: "Prefetch API",
          subtitle: "prefetch(_:) · prefetch(urls:) · cancelPrefetch · batch limits",
          make: { FKImageLoaderExamplePrefetchViewController() }
        ),
      ]
    ),
    Section(
      title: "FKImageLoader · Cache & configuration",
      rows: [
        Row(
          title: "Cache inspector",
          subtitle: "cachedImage · store · remove · clearMemoryCache · cacheStatistics",
          make: { FKImageLoaderExampleCacheInspectorViewController() }
        ),
        Row(
          title: "Configuration & events",
          subtitle: "apply(_:) · onEvent metrics · trimMemoryCache · flushDiskCacheIndex",
          make: { FKImageLoaderExampleConfigurationViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ImageView"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 76
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
