import UIKit

/// Grouped index of baseline and enhancement ``FKFileManager`` scenarios.
final class FKFileManagerExamplesHubViewController: UITableViewController {
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
      title: "Baseline",
      rows: [
        Row(title: "SandboxPaths", subtitle: "directoryURL for home, documents, caches, temporary", make: { FKFileManagerExampleSandboxPathsViewController() }),
        Row(title: "WriteReadModel", subtitle: "writeModel / readModel Codable round-trip", make: { FKFileManagerExampleWriteReadModelViewController() }),
        Row(title: "DownloadPauseResume", subtitle: "download, pauseDownload, resumeDownload, cancel", make: { FKFileManagerExampleDownloadPauseResumeViewController() }),
        Row(title: "MultipartUpload", subtitle: "Multiple files + form fields via FKUploadRequest", make: { FKFileManagerExampleMultipartUploadViewController() }),
        Row(title: "CacheSizeAndClear", subtitle: "directorySize, clearCaches, clearTemporaryFiles", make: { FKFileManagerExampleCacheSizeAndClearViewController() }),
        Row(title: "DiskSpaceGuard", subtitle: "ensureSufficientDiskSpace threshold check", make: { FKFileManagerExampleDiskSpaceGuardViewController() }),
        Row(title: "PersistedTransfers", subtitle: "persistedTransfers snapshot list after transfers", make: { FKFileManagerExamplePersistedTransfersViewController() }),
        Row(title: "ShareAndPreview", subtitle: "makeShareController + makePreviewController", make: { FKFileManagerExampleShareAndPreviewViewController() }),
      ]
    ),
    Section(
      title: "Enhancements",
      rows: [
        Row(title: "ZipFolder", subtitle: "Zip a directory with FKZipOptions", make: { FKFileManagerExampleZipFolderViewController() }),
        Row(title: "UnzipAndVerify", subtitle: "Unzip archive and compare SHA-256 hashes", make: { FKFileManagerExampleUnzipAndVerifyViewController() }),
        Row(title: "ZipSingleFile", subtitle: "Archive one file without root folder name", make: { FKFileManagerExampleZipSingleFileViewController() }),
        Row(title: "ZipUnavailableFallback", subtitle: "isZipEnabled gate → zipUnavailable", make: { FKFileManagerExampleZipUnavailableViewController() }),
        Row(title: "InsufficientDiskSpace", subtitle: "Compression blocked when disk guard fails", make: { FKFileManagerExampleInsufficientDiskSpaceViewController() }),
        Row(title: "ZipSlipBlocked", subtitle: "Malicious ../ entry → zipEntryPathUnsafe", make: { FKFileManagerExampleZipSlipBlockedViewController() }),
        Row(title: "BackgroundDownloadRecovery", subtitle: "persistedTransfers + AppDelegate wiring guide", make: { FKFileManagerExampleBackgroundRecoveryViewController() }),
        Row(title: "ShareZippedExport", subtitle: "zipItem then makeShareController", make: { FKFileManagerExampleShareZippedExportViewController() }),
      ]
    ),
    Section(
      title: "Catalog",
      rows: [
        Row(
          title: "Complete API catalog",
          subtitle: "Single-screen tour of every public FKFileManager API",
          make: { FKFileManagerExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKFileManager"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
