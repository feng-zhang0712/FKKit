import UIKit

/// Scrollable actions and monospace log shared by local notification scenario demos.
@MainActor
class FKLocalNotificationExampleBaseViewController: UIViewController {
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
    logView.text.append(line + "\n")
    let range = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(range)
  }

  func clearLog() {
    logView.text = ""
  }

  func addSectionHeading(_ title: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = title
    stackView.addArrangedSubview(label)
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
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.buttonSize = .small
    config.titleAlignment = .leading
    config.baseBackgroundColor = .secondarySystemFill
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    let button = UIButton(configuration: config)
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    stackView.addArrangedSubview(button)
  }

  func addClearLogButton() {
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }

  func runTask(_ label: String, operation: @escaping () async throws -> Void) {
    appendLog("[\(label)] started…")
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        try await operation()
        self.appendLog("[\(label)] success")
      } catch {
        self.appendLog("[\(label)] error: \(FKLocalNotificationExampleSupport.formatError(error))")
      }
    }
  }

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8
    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.46),
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
