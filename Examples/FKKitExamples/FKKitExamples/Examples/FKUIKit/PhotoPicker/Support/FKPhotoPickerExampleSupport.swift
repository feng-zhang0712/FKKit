import FKUIKit
import UIKit

enum FKPhotoPickerExampleUI {
  static func section(title: String, description: String, body: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    titleLabel.text = title

    let descriptionLabel = UILabel()
    descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.text = description

    wrap.addArrangedSubview(titleLabel)
    wrap.addArrangedSubview(descriptionLabel)
    wrap.addArrangedSubview(body)
    return wrap
  }

  static func button(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    var configuration = UIButton.Configuration.gray()
    configuration.cornerStyle = .medium
    configuration.title = title
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    configuration.titleLineBreakMode = .byWordWrapping
    configuration.titleAlignment = .center
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = .preferredFont(forTextStyle: .callout)
      return outgoing
    }
    button.configuration = configuration
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}

@MainActor
final class FKPhotoPickerExampleLog {
  static let shared = FKPhotoPickerExampleLog()

  private(set) var lines: [String] = []
  private var observers: [UUID: () -> Void] = [:]

  private init() {}

  var displayText: String {
    lines.isEmpty ? "Pick events will appear here." : lines.joined(separator: "\n")
  }

  func append(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    lines.insert("[\(stamp)] \(line)", at: 0)
    if lines.count > 60 {
      lines.removeLast(lines.count - 60)
    }
    observers.values.forEach { $0() }
  }

  func clear() {
    lines.removeAll()
    observers.values.forEach { $0() }
  }

  @discardableResult
  func addObserver(_ handler: @escaping () -> Void) -> UUID {
    let id = UUID()
    observers[id] = handler
    return id
  }

  func removeObserver(_ id: UUID) {
    observers.removeValue(forKey: id)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}

enum FKPhotoPickerExampleFormatting {
  static func summary(for result: FKPhotoPickerResult) -> String {
    var parts: [String] = [
      "id=\(result.id.prefix(8))…",
      "type=\(result.mediaType)",
      "pixels=\(Int(result.pixelSize.width))×\(Int(result.pixelSize.height))",
    ]
    if let bytes = result.byteCount {
      parts.append("bytes=\(bytes)")
    }
    if result.image != nil { parts.append("image=✓") }
    if result.data != nil { parts.append("data=✓") }
    if result.fileURL != nil { parts.append("fileURL=✓") }
    if result.thumbnail != nil { parts.append("thumbnail=✓") }
    if let assetID = result.assetIdentifier {
      parts.append("assetID=\(assetID.prefix(8))…")
    }
    return parts.joined(separator: ", ")
  }

  static func describe(_ error: FKPhotoPickerError) -> String {
    switch error {
    case .cancelled:
      return "cancelled (user dismissed without a selection)"
    case let .permissionDenied(kind):
      return "permissionDenied(\(kind))"
    case let .permissionError(error):
      return "permissionError: \(error.localizedDescription)"
    case .cameraUnavailable:
      return "cameraUnavailable"
    case .sourceUnavailable:
      return "sourceUnavailable"
    case .alreadyPresenting:
      return "alreadyPresenting"
    case let .selectionLimitExceeded(selected, limit):
      return "selectionLimitExceeded(selected: \(selected), limit: \(limit))"
    case let .processingFailed(description):
      return "processingFailed: \(description)"
    case let .fileTooLarge(bytes, max):
      return "fileTooLarge(\(bytes) > \(max))"
    case .unsupportedMediaType:
      return "unsupportedMediaType"
    case .emptySelection:
      return "emptySelection"
    case let .underlying(code, domain):
      return "underlying(\(domain), \(code))"
    }
  }
}

/// Scrollable demo shell with preview strip and event log.
@MainActor
class FKPhotoPickerExampleBaseViewController: UIViewController {
  let contentStack = UIStackView()
  let previewStack = UIStackView()
  private let logTextView = UITextView()
  private var logObserverID: UUID?
  private(set) var picker = FKPhotoPicker()
  private var trackedTempURLs: [URL] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    previewStack.axis = .horizontal
    previewStack.spacing = 8
    previewStack.alignment = .center
    previewStack.distribution = .fillEqually

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    contentStack.axis = .vertical
    contentStack.spacing = 16
    contentStack.alignment = .fill
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    logTextView.translatesAutoresizingMaskIntoConstraints = false
    logTextView.isEditable = false
    logTextView.isScrollEnabled = true
    logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logTextView.textColor = .secondaryLabel
    logTextView.backgroundColor = .secondarySystemGroupedBackground
    logTextView.layer.cornerRadius = 10
    logTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    let previewHeader = UILabel()
    previewHeader.text = "Preview"
    previewHeader.font = .preferredFont(forTextStyle: .subheadline)
    previewHeader.textColor = .secondaryLabel

    let previewWrap = UIStackView(arrangedSubviews: [previewHeader, previewStack])
    previewWrap.axis = .vertical
    previewWrap.spacing = 6

    let logHeader = UILabel()
    logHeader.text = "Event log"
    logHeader.font = .preferredFont(forTextStyle: .subheadline)
    logHeader.textColor = .secondaryLabel

    let bottomStack = UIStackView(arrangedSubviews: [previewWrap, logHeader, logTextView])
    bottomStack.axis = .vertical
    bottomStack.spacing = 6
    bottomStack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    view.addSubview(bottomStack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -8),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

      bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

      previewStack.heightAnchor.constraint(equalToConstant: 72),
      logTextView.heightAnchor.constraint(equalToConstant: 120),
    ])

    logObserverID = FKPhotoPickerExampleLog.shared.addObserver { [weak self] in
      self?.refreshLog()
    }
    refreshLog()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed, let logObserverID {
      FKPhotoPickerExampleLog.shared.removeObserver(logObserverID)
      self.logObserverID = nil
    }
  }

  func refreshLog() {
    logTextView.text = FKPhotoPickerExampleLog.shared.displayText
  }

  func log(_ message: String) {
    FKPhotoPickerExampleLog.shared.append(message)
  }

  func addClearLogButton() {
    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.button("Clear log") {
        FKPhotoPickerExampleLog.shared.clear()
      }
    )
  }

  func trackTempURLs(from results: [FKPhotoPickerResult]) {
    for result in results {
      if let url = result.fileURL {
        trackedTempURLs.append(url)
      }
    }
  }

  func cleanupTrackedTempFiles() {
    let fileManager = FileManager.default
    for url in trackedTempURLs {
      try? fileManager.removeItem(at: url)
    }
    trackedTempURLs.removeAll()
    log("Deleted tracked temp file URLs.")
  }

  func showResults(_ results: [FKPhotoPickerResult], label: String) {
    trackTempURLs(from: results)
    log("\(label): \(results.count) item(s)")
    for (index, result) in results.enumerated() {
      log("  [\(index)] \(FKPhotoPickerExampleFormatting.summary(for: result))")
    }
    updatePreview(with: results)
  }

  func showError(_ error: Error, label: String) {
    if let pickerError = error as? FKPhotoPickerError {
      log("\(label): \(FKPhotoPickerExampleFormatting.describe(pickerError))")
    } else {
      log("\(label): \(error.localizedDescription)")
    }
  }

  func pick(
    label: String,
    configuration: FKPhotoPickerConfiguration,
    popoverAnchor: FKPhotoPickerPopoverAnchor? = nil,
    progressHandler: FKPhotoPickerProgressHandler? = nil
  ) {
    Task { @MainActor in
      do {
        let results = try await picker.pick(
          from: self,
          configuration: configuration,
          popoverAnchor: popoverAnchor,
          progressHandler: progressHandler
        )
        showResults(results, label: label)
      } catch {
        showError(error, label: label)
      }
    }
  }

  private func updatePreview(with results: [FKPhotoPickerResult]) {
    previewStack.arrangedSubviews.forEach { view in
      previewStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    let previews = results.prefix(4)
    if previews.isEmpty {
      let placeholder = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
      placeholder.tintColor = .tertiaryLabel
      placeholder.contentMode = .scaleAspectFit
      previewStack.addArrangedSubview(placeholder)
      return
    }

    for result in previews {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      imageView.layer.cornerRadius = 8
      imageView.backgroundColor = .tertiarySystemFill
      imageView.image = result.image ?? result.thumbnail
      previewStack.addArrangedSubview(imageView)
    }

    if results.count > 4 {
      let more = UILabel()
      more.text = "+\(results.count - 4)"
      more.font = .preferredFont(forTextStyle: .caption1)
      more.textColor = .secondaryLabel
      more.textAlignment = .center
      previewStack.addArrangedSubview(more)
    }
  }
}
