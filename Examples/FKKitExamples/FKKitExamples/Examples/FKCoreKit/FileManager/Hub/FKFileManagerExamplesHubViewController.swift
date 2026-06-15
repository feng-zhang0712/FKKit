import UIKit

/// Grouped index of baseline (B1–B8) and enhancement (E1–E8) ``FKFileManager`` scenarios.
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
      title: "Baseline (B1–B8)",
      rows: [
        Row(title: "B1 SandboxPaths", subtitle: "directoryURL for home, documents, caches, temporary", make: { FKFileManagerExampleSandboxPathsViewController() }),
        Row(title: "B2 WriteReadModel", subtitle: "writeModel / readModel Codable round-trip", make: { FKFileManagerExampleWriteReadModelViewController() }),
        Row(title: "B3 DownloadPauseResume", subtitle: "download, pauseDownload, resumeDownload, cancel", make: { FKFileManagerExampleDownloadPauseResumeViewController() }),
        Row(title: "B4 MultipartUpload", subtitle: "Multiple files + form fields via FKUploadRequest", make: { FKFileManagerExampleMultipartUploadViewController() }),
        Row(title: "B5 CacheSizeAndClear", subtitle: "directorySize, clearCaches, clearTemporaryFiles", make: { FKFileManagerExampleCacheSizeAndClearViewController() }),
        Row(title: "B6 DiskSpaceGuard", subtitle: "ensureSufficientDiskSpace threshold check", make: { FKFileManagerExampleDiskSpaceGuardViewController() }),
        Row(title: "B7 PersistedTransfers", subtitle: "persistedTransfers snapshot list after transfers", make: { FKFileManagerExamplePersistedTransfersViewController() }),
        Row(title: "B8 ShareAndPreview", subtitle: "makeShareController + makePreviewController", make: { FKFileManagerExampleShareAndPreviewViewController() }),
      ]
    ),
    Section(
      title: "Enhancements (E1–E8)",
      rows: [
        Row(title: "E1 ZipFolder", subtitle: "Zip a directory with FKZipOptions", make: { FKFileManagerExampleZipFolderViewController() }),
        Row(title: "E2 UnzipAndVerify", subtitle: "Unzip archive and compare SHA-256 hashes", make: { FKFileManagerExampleUnzipAndVerifyViewController() }),
        Row(title: "E3 ZipSingleFile", subtitle: "Archive one file without root folder name", make: { FKFileManagerExampleZipSingleFileViewController() }),
        Row(title: "E4 ZipUnavailableFallback", subtitle: "isZipEnabled gate → zipUnavailable", make: { FKFileManagerExampleZipUnavailableViewController() }),
        Row(title: "E5 InsufficientDiskSpace", subtitle: "Compression blocked when disk guard fails", make: { FKFileManagerExampleInsufficientDiskSpaceViewController() }),
        Row(title: "E6 ZipSlipBlocked", subtitle: "Malicious ../ entry → zipEntryPathUnsafe", make: { FKFileManagerExampleZipSlipBlockedViewController() }),
        Row(title: "E7 BackgroundDownloadRecovery", subtitle: "persistedTransfers + AppDelegate wiring guide", make: { FKFileManagerExampleBackgroundRecoveryViewController() }),
        Row(title: "E8 ShareZippedExport", subtitle: "zipItem then makeShareController", make: { FKFileManagerExampleShareZippedExportViewController() }),
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
