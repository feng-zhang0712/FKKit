import FKCoreKit
import UIKit

enum FKQRCodeExampleUI {
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

enum FKQRCodeExampleFormatting {
  static func describe(_ payload: FKQRCodePayload) -> String {
    switch payload {
    case let .url(url):
      return "url(\(url.absoluteString))"
    case let .text(text):
      return "text(\(text))"
    case let .unknown(value):
      return "unknown(\(value))"
    }
  }

  static func describe(_ error: FKQRCodeError) -> String {
    switch error {
    case .emptyContent:
      return "emptyContent"
    case let .contentTooLong(maxBytes):
      return "contentTooLong(maxBytes: \(maxBytes))"
    case .filterFailed:
      return "filterFailed"
    case .imageConversionFailed:
      return "imageConversionFailed"
    }
  }
}

@MainActor
final class FKQRCodeExampleLog {
  static let shared = FKQRCodeExampleLog()

  private(set) var lines: [String] = []
  private var observers: [UUID: () -> Void] = [:]

  private init() {}

  var displayText: String {
    lines.isEmpty ? "Events will appear here." : lines.joined(separator: "\n")
  }

  func append(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    lines.insert("[\(stamp)] \(line)", at: 0)
    if lines.count > 80 {
      lines.removeLast(lines.count - 80)
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
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}

/// Scrollable shell with optional QR preview and event log for FKCoreKit QR demos.
@MainActor
class FKQRCodeExampleBaseViewController: UIViewController {
  let contentStack = UIStackView()
  let previewImageView = UIImageView()
  private let logTextView = UITextView()
  private var logObserverID: UUID?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    contentStack.axis = .vertical
    contentStack.spacing = 16
    contentStack.alignment = .fill
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    previewImageView.translatesAutoresizingMaskIntoConstraints = false
    previewImageView.contentMode = .scaleAspectFit
    previewImageView.backgroundColor = .secondarySystemGroupedBackground
    previewImageView.layer.cornerRadius = 12
    previewImageView.clipsToBounds = true
    previewImageView.isHidden = true

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

    let previewWrap = UIStackView(arrangedSubviews: [previewHeader, previewImageView])
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

      previewImageView.heightAnchor.constraint(equalToConstant: 220),
      logTextView.heightAnchor.constraint(equalToConstant: 120),
    ])

    logObserverID = FKQRCodeExampleLog.shared.addObserver { [weak self] in
      self?.refreshLog()
    }
    refreshLog()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed, let logObserverID {
      FKQRCodeExampleLog.shared.removeObserver(logObserverID)
      self.logObserverID = nil
    }
  }

  func refreshLog() {
    logTextView.text = FKQRCodeExampleLog.shared.displayText
  }

  func log(_ message: String) {
    FKQRCodeExampleLog.shared.append(message)
  }

  func addClearLogButton() {
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.button("Clear log") {
        FKQRCodeExampleLog.shared.clear()
      }
    )
  }

  func showPreview(_ image: UIImage?) {
    previewImageView.isHidden = image == nil
    previewImageView.image = image
  }

  func generateAndPreview(
    label: String,
    content: String,
    options: FKQRCodeGenerationOptions = .default
  ) {
    do {
      let image = try FKQRCodeGenerator.makeImage(from: content, options: options)
      showPreview(image)
      log("\(label): generated \(Int(options.size.width))×\(Int(options.size.height)), correction=\(options.correctionLevel.rawValue)")
    } catch let error as FKQRCodeError {
      showPreview(nil)
      log("\(label): \(FKQRCodeExampleFormatting.describe(error))")
    } catch {
      showPreview(nil)
      log("\(label): \(error.localizedDescription)")
    }
  }
}
