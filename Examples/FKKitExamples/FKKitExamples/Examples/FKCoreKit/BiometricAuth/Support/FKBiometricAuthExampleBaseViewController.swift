import FKCoreKit
import UIKit

/// Scroll + action buttons + monospace log for FKBiometricAuth demos.
@MainActor
class FKBiometricAuthExampleBaseViewController: UIViewController {
  let stackView = UIStackView()
  private let scrollView = UIScrollView()
  private let logView = UITextView()

  private var logLines: [String] = []
  private var isBusy = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never
    buildLayout()
  }

  func appendLog(_ line: String) {
    logLines.append(line)
    if logLines.count > 100 {
      logLines.removeFirst(logLines.count - 100)
    }
    logView.text = logLines.joined(separator: "\n")
    let range = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(range)
  }

  func clearLog() {
    logLines.removeAll()
    logView.text = ""
  }

  @discardableResult
  func addSectionHeading(_ title: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = title
    stackView.addArrangedSubview(label)
    return label
  }

  func addInfoLabel(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    stackView.addArrangedSubview(label)
  }

  /// Required for any scenario that presents the system Face ID / Touch ID sheet on Simulator.
  func addSimulatorFaceIDGuide() {
    let container = UIView()
    container.backgroundColor = .secondarySystemBackground
    container.layer.cornerRadius = 10
    container.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .label
    label.text = """
    Simulator Face ID (no Mac camera needed):
    1. Simulator menu → Features → Face ID → Enrolled (once per session)
    2. Set a device passcode: Settings app → Face ID & Passcode (recommended for Simulator)
    3. Tap authenticate below — on the first scan sheet, use Features → Face ID → Matching Face

    Avoid “Try Face ID Again” on Simulator: on many OS versions it does not return to the scan UI (Apple Simulator limitation). If you see “Face Not Recognized”, tap Cancel, then restart auth below or use devicePasscode.
    """
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
    ])
    stackView.addArrangedSubview(container)
  }

  /// Escape hatch when the system Face ID sheet is stuck (common Simulator quirk).
  func addSimulatorRecoverySection(auth: FKBiometricAuthenticating) {
    addSectionHeading("Simulator recovery")
    addInfoLabel(
      "System “Try Face ID Again” is controlled by iOS, not FKBiometricAuth. When it appears stuck, tap Cancel on the system sheet, then use cancelAuthentication or restart authenticate here."
    )

    addActionButton("cancelAuthentication() — force-dismiss stuck sheet") {
      auth.cancelAuthentication()
      self.appendLog("cancelAuthentication() dispatched → expect appCancelled if auth was in flight")
    }

    addActionButton("Authenticate (devicePasscode) — simulator passcode keypad") { [weak self] in
      self?.runAuthTask("simulator.passcode") {
        try await auth.authenticate(
          reason: "Enter simulator device passcode",
          policy: .devicePasscode,
          options: .init()
        )
      }
    }

    addActionButton("Open Settings — set Face ID Enrolled & passcode") { [weak self] in
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
      self?.appendLog("Opened Settings — enable passcode, then Features → Face ID → Enrolled in Simulator menu")
    }
  }

  @discardableResult
  func addActionButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.buttonSize = .small
    config.titleAlignment = .leading
    config.baseBackgroundColor = .secondarySystemFill
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    let button = UIButton(configuration: config)
    button.isExclusiveTouch = true
    button.addAction(UIAction { [weak self] _ in
      guard let self, self.isBusy == false else {
        self?.appendLog("[skipped] action ignored — authentication in progress")
        return
      }
      action()
    }, for: .touchUpInside)
    stackView.addArrangedSubview(button)
    return button
  }

  func addClearLogButton() {
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }

  func runAuthTask(_ label: String, operation: @escaping () async throws -> Void) {
    isBusy = true
    appendLog("[\(label)] started…")
    Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.isBusy = false }
      do {
        try await operation()
        self.appendLog("[\(label)] success")
      } catch {
        self.appendLog("[\(label)] error: \(FKBiometricAuthExampleSupport.formatError(error))")
      }
    }
  }

  func runClosureAuth(
    _ label: String,
    auth: FKBiometricAuthenticating,
    reason: String
  ) {
    isBusy = true
    appendLog("[\(label)] started…")
    auth.authenticate(reason: reason) { [weak self] result in
      Task { @MainActor in
        guard let self else { return }
        self.isBusy = false
        switch result {
        case .success:
          self.appendLog("[\(label)] success")
        case let .failure(error):
          self.appendLog("[\(label)] error: \(FKBiometricAuthExampleSupport.formatError(error))")
        }
      }
    }
  }

  func runCancellableAuthTask(_ label: String, operation: @escaping () async throws -> Void) -> Task<Void, Never> {
    isBusy = true
    appendLog("[\(label)] started (cancellable Task)…")
    return Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.isBusy = false }
      do {
        try await operation()
        self.appendLog("[\(label)] success")
      } catch is CancellationError {
        self.appendLog("[\(label)] Swift Task cancelled")
      } catch {
        self.appendLog("[\(label)] error: \(FKBiometricAuthExampleSupport.formatError(error))")
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

    scrollView.addSubview(stackView)
    view.addSubview(scrollView)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.48),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -4),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
