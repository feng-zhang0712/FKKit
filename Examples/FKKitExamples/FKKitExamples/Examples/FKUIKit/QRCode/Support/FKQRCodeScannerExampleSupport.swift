import FKCoreKit
import FKUIKit
import UIKit

enum FKQRCodeScannerExampleFormatting {
  static func describe(_ error: FKQRCodeScannerError) -> String {
    switch error {
    case .cameraUnavailable:
      return "cameraUnavailable"
    case .permissionDenied:
      return "permissionDenied"
    case .sessionConfigurationFailed:
      return "sessionConfigurationFailed"
    case .interrupted:
      return "interrupted"
    }
  }
}

/// Retains itself while presented so delegate callbacks stay alive.
@MainActor
final class FKQRCodeScannerExampleSession: NSObject, FKQRCodeScannerDelegate {
  var onEvent: ((String) -> Void)?

  private var retainSelf: FKQRCodeScannerExampleSession?

  func present(
    from presenter: UIViewController,
    configuration: FKQRCodeScannerConfiguration = .default
  ) {
    retainSelf = self
    let scanner = FKQRCodeScannerViewController(configuration: configuration)
    scanner.delegate = self
    presenter.present(scanner, animated: true)
  }

  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didScan payload: FKQRCodePayload) {
    onEvent?("didScan → \(FKQRCodeExampleFormatting.describe(payload))")
    scanner.dismiss(animated: true) { [weak self] in
      self?.releaseSession()
    }
  }

  func qrCodeScannerDidCancel(_ scanner: FKQRCodeScannerViewController) {
    onEvent?("didCancel")
    releaseSession()
  }

  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didFail error: FKQRCodeScannerError) {
    onEvent?("didFail → \(FKQRCodeScannerExampleFormatting.describe(error))")
    releaseSession()
  }

  private func releaseSession() {
    retainSelf = nil
  }
}

/// Scrollable shell with event log for FKUIKit QR scanner demos.
@MainActor
class FKQRCodeScannerExampleBaseViewController: UIViewController {
  let contentStack = UIStackView()
  private let logTextView = UITextView()
  private var logObserverID: UUID?
  private var activeSession: FKQRCodeScannerExampleSession?

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

    let bottomStack = UIStackView(arrangedSubviews: [logHeader, logTextView])
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

      logTextView.heightAnchor.constraint(equalToConstant: 160),
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

  func presentScanner(
    label: String,
    configuration: FKQRCodeScannerConfiguration = .default
  ) {
    log("\(label): presenting scanner…")
    let session = FKQRCodeScannerExampleSession()
    session.onEvent = { [weak self] line in
      self?.log("\(label): \(line)")
    }
    activeSession = session
    session.present(from: self, configuration: configuration)
  }

  func presentMessageAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
