import UIKit

/// Index of ``FKPhotoPicker`` examples, grouped by integration path.
final class FKPhotoPickerExamplesHubViewController: UITableViewController {
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
          title: "Basics",
          subtitle: "Library pick, async API, closure callback, cancel semantics",
          make: { FKPhotoPickerExampleBasicsViewController() }
        ),
        Row(
          title: "Presets & convenience",
          subtitle: "avatar, chatAttachments, documentScan, highQualitySingle, pickAvatar, pickImages, defaults",
          make: { FKPhotoPickerExamplePresetsViewController() }
        ),
      ]
    ),
    Section(
      title: "Sources & camera",
      rows: [
        Row(
          title: "Source chooser",
          subtitle: "libraryOrCamera (FKActionSheet), custom(FKPhotoPickerSource)",
          make: { FKPhotoPickerExampleSourceChooserViewController() }
        ),
        Row(
          title: "Camera capture",
          subtitle: "Rear/front camera, allowsEditing, documentScan preset",
          make: { FKPhotoPickerExampleCameraViewController() }
        ),
        Row(
          title: "Multi-select & progress",
          subtitle: "Up to 9 images, ordered results, progress(processed, total)",
          make: { FKPhotoPickerExampleMultiSelectViewController() }
        ),
      ]
    ),
    Section(
      title: "Output & processing",
      rows: [
        Row(
          title: "Delivery modes",
          subtitle: "image, compressedData, fileURL, imageAndFileURL, imageAndData",
          make: { FKPhotoPickerExampleDeliveryViewController() }
        ),
        Row(
          title: "Compression & privacy",
          subtitle: "maxPixelDimension downscale, stripLocationEXIF, high quality, overflow takeFirst",
          make: { FKPhotoPickerExampleProcessingViewController() }
        ),
        Row(
          title: "Video picking",
          subtitle: "Library video fileURL, thumbnail, maxVideoBytes limit",
          make: { FKPhotoPickerExampleVideoViewController() }
        ),
        Row(
          title: "Live Photo policies",
          subtitle: "stillImageOnly vs skip when livePhotos filter is enabled",
          make: { FKPhotoPickerExampleLivePhotoViewController() }
        ),
      ]
    ),
    Section(
      title: "Permissions & lifecycle",
      rows: [
        Row(
          title: "Permission flows",
          subtitle: "Pre-prompt, checksPhotoLibrary, opensSettingsOnDenied, limited library management",
          make: { FKPhotoPickerExamplePermissionsViewController() }
        ),
        Row(
          title: "Presentation",
          subtitle: "automatic, pageSheet, fullScreen, popover anchor (iPad-friendly)",
          make: { FKPhotoPickerExamplePresentationViewController() }
        ),
        Row(
          title: "Lifecycle & temp files",
          subtitle: "alreadyPresenting guard, temp file policies, host cleanup",
          make: { FKPhotoPickerExampleLifecycleViewController() }
        ),
      ]
    ),
    Section(
      title: "Integration",
      rows: [
        Row(
          title: "SwiftUI bridge",
          subtitle: "FKPhotoPickerButton resolves presenter and runs pick()",
          make: { FKPhotoPickerExampleSwiftUIViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKPhotoPicker"
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
