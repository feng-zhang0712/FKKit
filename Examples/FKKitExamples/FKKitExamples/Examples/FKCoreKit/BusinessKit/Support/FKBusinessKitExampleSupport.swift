import UIKit
import FKCoreKit

/// Scrollable actions and monospace log shared by BusinessKit scenario demos.
@MainActor
class FKBusinessKitExampleBaseViewController: UIViewController {
  let kit = FKBusinessKit.shared
  let stackView = UIStackView()
  private let scrollView = UIScrollView()
  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never
    buildLayout()
  }

  func appendLog(_ line: String) {
    let stamp = DateFormatter.businessKitExampleFormatter.string(from: Date())
    logView.text.append("[\(stamp)] \(line)\n")
    let range = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(range)
  }

  func clearLog() {
    logView.text = ""
  }

  func addInfoLabel(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    stackView.addArrangedSubview(label)
  }

  func addActionButton(_ title: String, action: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.textAlignment = .left
    button.contentHorizontalAlignment = .leading
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    stackView.addArrangedSubview(button)
  }

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8
    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.42),
      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}

// MARK: - Demo collaborators

enum FKBusinessKitDemoRemoteVersionMode {
  case upToDate
  case optionalUpdate
  case forceUpdate
}

final class FKBusinessKitDemoRemoteVersionProvider: FKRemoteVersionProviding {
  private let mode: FKBusinessKitDemoRemoteVersionMode

  init(mode: FKBusinessKitDemoRemoteVersionMode) {
    self.mode = mode
  }

  @available(iOS 13.0, *)
  func fetchRemoteVersion() async throws -> FKRemoteVersionInfo {
    try await Task.sleep(nanoseconds: 250_000_000)
    switch mode {
    case .upToDate:
      return FKRemoteVersionInfo(
        version: FKBusinessKit.shared.info.appVersion,
        releaseNotes: "You are up to date.",
        updateURL: URL(string: "https://apps.apple.com")
      )
    case .optionalUpdate:
      return FKRemoteVersionInfo(
        version: "99.0.0",
        releaseNotes: "Optional update available.",
        updateURL: URL(string: "https://apps.apple.com"),
        isForceUpdate: false
      )
    case .forceUpdate:
      return FKRemoteVersionInfo(
        version: "99.0.0",
        releaseNotes: "Forced update required.",
        updateURL: URL(string: "https://apps.apple.com"),
        isForceUpdate: true
      )
    }
  }
}

final class FKBusinessKitDemoAnalyticsCommonParamsProvider: FKAnalyticsCommonParametersProviding {
  func commonParameters() -> [String: String] {
    ["demo_region": "US", "demo_source": "BusinessKitExamples"]
  }
}

final class FKBusinessKitDemoAnalyticsUploader: FKAnalyticsUploading {
  private let logger: (String) -> Void
  private let counter = DemoUploadCounter()

  init(logger: @escaping (String) -> Void) {
    self.logger = logger
  }

  @available(iOS 13.0, *)
  func upload(batch: [FKAnalyticsEvent]) async throws {
    try await Task.sleep(nanoseconds: 200_000_000)
    let current = await counter.next()
    if current % 3 == 0 {
      logger("Upload failed (simulated) batch=\(batch.count)")
      throw NSError(domain: "demo.analytics", code: -1)
    }
    logger("Upload succeeded batch=\(batch.count)")
  }
}

private actor DemoUploadCounter {
  private var value = 0

  func next() -> Int {
    value += 1
    return value
  }
}

extension DateFormatter {
  static let businessKitExampleFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
