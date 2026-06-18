import UIKit

/// Grouped index of ``FKMediaGallery`` examples covering every public integration path.
final class FKMediaGalleryExamplesHubViewController: UITableViewController {
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
      title: "Getting started",
      rows: [
        Row(
          title: "Social feed post",
          subtitle: "9 images + 1 video · hero · progressive loading · numeric indicator",
          make: { FKMediaGalleryExampleSocialFeedViewController() }
        ),
        Row(
          title: "Configuration presets",
          subtitle: "socialFeed, chatAttachments, productDetail, previewOnly, authenticatedCDN",
          make: { FKMediaGalleryExamplePresetsViewController() }
        ),
        Row(
          title: "Single image",
          subtitle: "One page · page indicator hidden",
          make: { FKMediaGalleryExampleSingleImageViewController() }
        ),
        Row(
          title: "Product detail",
          subtitle: "productDetail() · 6× max zoom · captions",
          make: { FKMediaGalleryExampleProductDetailViewController() }
        ),
      ]
    ),
    Section(
      title: "Media sources",
      rows: [
        Row(
          title: "Local mixed gallery",
          subtitle: "UIImage · file:// image · cached local MP4",
          make: { FKMediaGalleryExampleLocalMixedViewController() }
        ),
        Row(
          title: "Remote mixed gallery",
          subtitle: "HTTPS image · progressive MP4 · HLS VOD",
          make: { FKMediaGalleryExampleRemoteMixedViewController() }
        ),
        Row(
          title: "Local + remote mixed",
          subtitle: "Same items array · local and remote kinds together",
          make: { FKMediaGalleryExampleLocalRemoteMixedViewController() }
        ),
        Row(
          title: "Remote loading & failure",
          subtitle: "Loading progress · 404 retry · didFailToLoad delegate",
          make: { FKMediaGalleryExampleRemoteLoadingViewController() }
        ),
        Row(
          title: "Thumbnail cache shared",
          subtitle: "Feed FKImageView cacheKey matches gallery full-size key",
          make: { FKMediaGalleryExampleThumbnailCacheViewController() }
        ),
        Row(
          title: "Authenticated media",
          subtitle: "Video URL with Authorization headers on FKMediaSource",
          make: { FKMediaGalleryExampleAuthenticatedViewController() }
        ),
      ]
    ),
    Section(
      title: "Gestures & video",
      rows: [
        Row(
          title: "Zoom gestures",
          subtitle: "Pinch · focal double-tap · paging arbitration when zoomed",
          make: { FKMediaGalleryExampleZoomGesturesViewController() }
        ),
        Row(
          title: "Swipe to dismiss",
          subtitle: "Interactive dismiss · close button · dimming",
          make: { FKMediaGalleryExampleSwipeToDismissViewController() }
        ),
        Row(
          title: "Video autoplay",
          subtitle: "FKVideoPlayer · Wi‑Fi only · scrub · offscreen teardown",
          make: { FKMediaGalleryExampleVideoAutoplayViewController() }
        ),
        Row(
          title: "Context menu · share · save",
          subtitle: "Long-press · FKFileManager share · save to Photos",
          make: { FKMediaGalleryExampleContextMenuViewController() }
        ),
        Row(
          title: "Full video player handoff",
          subtitle: "Delegate → FKVideoPlayerViewController for full chrome",
          make: { FKMediaGalleryExampleFullVideoHandoffViewController() }
        ),
      ]
    ),
    Section(
      title: "Runtime & integration",
      rows: [
        Row(
          title: "Chat preview · updateItems",
          subtitle: "chatAttachments() · delete attachment while presented",
          make: { FKMediaGalleryExampleChatPreviewViewController() }
        ),
        Row(
          title: "PhotoPicker bridge",
          subtitle: "FKPhotoPicker → FKMediaGalleryItem.from(results)",
          make: { FKMediaGalleryExamplePhotoPickerBridgeViewController() }
        ),
        Row(
          title: "Custom chrome overlay",
          subtitle: "FKMediaGalleryChromeProviding per-page injection",
          make: { FKMediaGalleryExampleCustomChromeViewController() }
        ),
        Row(
          title: "SwiftUI presenter",
          subtitle: "FKMediaGalleryPresenter · View.fkMediaGallery modifier",
          make: { FKMediaGalleryExampleSwiftUIViewController() }
        ),
      ]
    ),
    Section(
      title: "Accessibility & layout",
      rows: [
        Row(
          title: "Reduce Motion",
          subtitle: "Hero degrades to cross-dissolve when Reduce Motion is on",
          make: { FKMediaGalleryExampleReduceMotionViewController() }
        ),
        Row(
          title: "RTL gallery",
          subtitle: "Right-to-left layout · mirrored paging semantics",
          make: { FKMediaGalleryExampleRTLViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKMediaGallery"
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
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
