import UIKit

/// Shared layout helpers for FKActionSheet demo screens.
enum FKActionSheetExampleUI {
  static func section(title: String, description: String, body: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0
    titleLabel.text = title

    let descriptionLabel = UILabel()
    descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
    descriptionLabel.adjustsFontForContentSizeCategory = true
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.text = description

    wrap.addArrangedSubview(titleLabel)
    wrap.addArrangedSubview(descriptionLabel)
    wrap.addArrangedSubview(body)
    return wrap
  }

  static func row(_ views: [UIView]) -> UIStackView {
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    return row
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

  static func anchorButton(title: String) -> UIButton {
    let button = UIButton(type: .system)
    var configuration = UIButton.Configuration.gray()
    configuration.cornerStyle = .medium
    configuration.baseBackgroundColor = .tertiarySystemFill
    configuration.title = title
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = .preferredFont(forTextStyle: .body)
      return outgoing
    }
    button.configuration = configuration
    return button
  }
}

@MainActor
final class FKActionSheetExampleEventLog {
  static let shared = FKActionSheetExampleEventLog()

  private(set) var lines: [String] = []
  private var observers: [UUID: () -> Void] = [:]

  private init() {}

  var displayText: String {
    lines.isEmpty ? "Events will appear here." : lines.joined(separator: "\n")
  }

  func append(_ line: String) {
    let stamp = Self.timeFormatter.string(from: Date())
    lines.insert("[\(stamp)] \(line)", at: 0)
    if lines.count > 50 {
      lines.removeLast(lines.count - 50)
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

/// Scrollable demo shell with a shared event log panel.
class FKActionSheetExampleBaseViewController: UIViewController {
  let contentStack = UIStackView()
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

    logTextView.translatesAutoresizingMaskIntoConstraints = false
    logTextView.isEditable = false
    logTextView.isScrollEnabled = true
    logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logTextView.textColor = .secondaryLabel
    logTextView.backgroundColor = .secondarySystemGroupedBackground
    logTextView.layer.cornerRadius = 10
    logTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    let logHeader = UILabel()
    logHeader.text = "Event log"
    logHeader.font = .preferredFont(forTextStyle: .subheadline)
    logHeader.textColor = .secondaryLabel

    let logStack = UIStackView(arrangedSubviews: [logHeader, logTextView])
    logStack.axis = .vertical
    logStack.spacing = 6
    logStack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    view.addSubview(logStack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: logStack.topAnchor, constant: -8),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

      logStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      logTextView.heightAnchor.constraint(equalToConstant: 120),
    ])

    logObserverID = FKActionSheetExampleEventLog.shared.addObserver { [weak self] in
      self?.refreshLog()
    }
    refreshLog()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed, let logObserverID {
      FKActionSheetExampleEventLog.shared.removeObserver(logObserverID)
      self.logObserverID = nil
    }
  }

  func refreshLog() {
    logTextView.text = FKActionSheetExampleEventLog.shared.displayText
  }

  func addClearLogButton() {
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.button("Clear log") {
        FKActionSheetExampleEventLog.shared.clear()
      }
    )
  }
}
