import FKCoreKit
import UIKit

private struct LoggerDemoUser: Codable, Sendable {
  let id: Int
  let name: String
  let tags: [String]
}

/// Interactive catalog of **public** `FKLogger` APIs: levels, global shortcuts, config, lazy messages,
/// file lifecycle, formatting toggles, diagnostics (`dumpValue` / `dumpEncodable`), crash/network hooks,
/// and an auxiliary `FKLogger` instance with isolated configuration.
///
/// Note: console output uses `Swift.print` only in **DEBUG** builds (`FKLogger`’s default console outputter).
/// On-screen text summarizes what was invoked; open the Xcode console to see formatted lines when debugging.
final class FKLoggerExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  private static var lazyMessageEvaluationCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKLogger"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("Loaded. DEBUG builds print colored lines to the Xcode console; this panel lists actions.")
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 6

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8

    let sections: [(title: String, rows: [(String, Selector)])] = [
      (
        "1. Entry points",
        [
          ("FKLogger.shared vs FKCoreKit.logger (same singleton)", #selector(demoSingletonVsNamespace)),
          ("FKLogger(config:) auxiliary instance (separate prefix, file off)", #selector(demoAuxiliaryLogger)),
        ]
      ),
      (
        "2. Levels — FKLogger.shared.verbose…error",
        [
          ("All five levels + metadata", #selector(demoLevelsOnShared)),
        ]
      ),
      (
        "3. Global shortcuts — FKLogV / FKLogD / FKLogI / FKLogW / FKLogE",
        [
          ("One line per helper (lazy-friendly autoclosure)", #selector(demoGlobalShortcuts)),
        ]
      ),
      (
        "4. Explicit pipeline — log(_:message:metadata:file:function:line:)",
        [
          ("Escaping closure message (full control)", #selector(demoExplicitLogClosure)),
          ("Lazy evaluation: disable .verbose then FKLogV (counter stays zero)", #selector(demoLazyEvaluationWhenFiltered)),
        ]
      ),
      (
        "5. FKLoggerConfig",
        [
          ("Read/write `config` property (struct copy)", #selector(demoConfigProperty)),
          ("updateConfig { … } atomic mutation", #selector(demoUpdateConfig)),
          ("setLevel(_:isEnabled:) toggle one level", #selector(demoSetLevel)),
          ("Apply FKLoggerConfig.debugDefault", #selector(demoApplyDebugPreset)),
          ("Apply FKLoggerConfig.releaseDefault", #selector(demoApplyReleasePreset)),
          ("Restore demo-friendly defaults", #selector(demoRestoreDemoDefaults)),
        ]
      ),
      (
        "6. Formatting toggles",
        [
          ("Verbose format: timestamp + file + function + line + emoji + color", #selector(demoFormatVerbose)),
          ("Compact format: timestamp + emoji only", #selector(demoFormatCompact)),
        ]
      ),
      (
        "7. dumpValue / dumpEncodable",
        [
          ("dumpEncodable(Codable model)", #selector(demoDumpEncodable)),
          ("dumpValue(Array)", #selector(demoDumpValueArray)),
          ("dumpValue(JSON-compatible Dictionary)", #selector(demoDumpValueDict)),
        ]
      ),
      (
        "8. File persistence",
        [
          ("Enable rotation + size limits + sample lines", #selector(demoEnableFileLogging)),
          ("allLogFiles()", #selector(demoListLogFiles)),
          ("flushSynchronously() then note ordering", #selector(demoFlush)),
          ("exportLogArchive() → share sheet", #selector(demoExportArchive)),
          ("clearLogFiles()", #selector(demoClearPersisted)),
        ]
      ),
      (
        "9. Crash monitor & diagnostics",
        [
          ("installCrashCapture() (idempotent)", #selector(demoInstallCrashCapture)),
          ("captureException(name:reason:metadata:)", #selector(demoCaptureException)),
          ("captureNetwork — HTTP 500 + error", #selector(demoCaptureNetworkError)),
          ("captureNetwork — HTTP 200 + body bytes", #selector(demoCaptureNetworkSuccess)),
        ]
      ),
      (
        "10. Build flavor",
        [
          ("Log under #if DEBUG / #else (release path)", #selector(demoBuildFlavor)),
        ]
      ),
      (
        "11. Output",
        [
          ("Clear on-screen log", #selector(clearOutput)),
        ]
      ),
    ]

    for section in sections {
      stackView.addArrangedSubview(makeSectionTitle(section.title))
      for row in section.rows {
        stackView.addArrangedSubview(makeButton(title: row.0, action: row.1))
      }
      stackView.setCustomSpacing(14, after: stackView.arrangedSubviews.last!)
    }

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      outputView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.accessibilityTraits.insert(.header)
    return label
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.textAlignment = .left
    button.contentHorizontalAlignment = .leading
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  // MARK: - Demos

  @objc private func demoSingletonVsNamespace() {
    FKLogger.shared.info("[FKLogger.shared] ping", metadata: ["channel": "shared"])
    FKCoreKit.logger.info("[FKCoreKit.logger] ping", metadata: ["channel": "namespace"])
    appendOutput("Called shared + FKCoreKit.logger (same underlying instance). Check metadata channel in console/file.")
  }

  private var auxiliaryLogger: FKLogger?

  @objc private func demoAuxiliaryLogger() {
    var cfg = FKLogger.shared.config
    cfg.prefix = "[FKLoggerExample/Aux]"
    cfg.persistsToFile = false
    cfg.isEnabled = true
    cfg.enabledLevels = [.info, .warning]
    let aux = FKLogger(config: cfg)
    auxiliaryLogger = aux
    aux.verbose("Auxiliary verbose (should be filtered out)")
    aux.info("Auxiliary info line")
    aux.warning("Auxiliary warning line")
    appendOutput("Created auxiliary FKLogger(config:): verbose disabled by enabledLevels; info+warning emitted.")
  }

  @objc private func demoLevelsOnShared() {
    FKLogger.shared.verbose("Level demo: verbose", metadata: ["step": "1"])
    FKLogger.shared.debug("Level demo: debug", metadata: ["step": "2"])
    FKLogger.shared.info("Level demo: info", metadata: ["step": "3"])
    FKLogger.shared.warning("Level demo: warning", metadata: ["step": "4"])
    FKLogger.shared.error("Level demo: error", metadata: ["step": "5"])
    appendOutput("Emitted verbose→error on FKLogger.shared with metadata.")
  }

  @objc private func demoGlobalShortcuts() {
    FKLogV("FKLogV global shortcut", metadata: ["api": "FKLogV"])
    FKLogD("FKLogD global shortcut", metadata: ["api": "FKLogD"])
    FKLogI("FKLogI global shortcut", metadata: ["api": "FKLogI"])
    FKLogW("FKLogW global shortcut", metadata: ["api": "FKLogW"])
    FKLogE("FKLogE global shortcut", metadata: ["api": "FKLogE"])
    appendOutput("FKLog* helpers route through shared.log(_:message:…) for lazy evaluation.")
  }

  @objc private func demoExplicitLogClosure() {
    FKLogger.shared.log(
      .info,
      message: { "Built from escaping closure at \(Date())" },
      metadata: ["style": "explicit"],
      file: "FKLoggerExampleViewController",
      function: "demoExplicitLogClosure",
      line: 1
    )
    appendOutput("Called log(_:message:…) with custom file/function labels (demo strings).")
  }

  @objc private func demoLazyEvaluationWhenFiltered() {
    Self.lazyMessageEvaluationCount = 0
    let previousVerbose = FKLogger.shared.config.enabledLevels.contains(.verbose)
    FKLogger.shared.setLevel(.verbose, isEnabled: false)
    FKLogger.shared.log(
      .verbose,
      message: {
        Self.lazyMessageEvaluationCount += 1
        return "Verbose body must not run while level is disabled"
      },
      metadata: ["test": "lazy"],
      file: #fileID,
      function: #function,
      line: #line
    )
    FKLogger.shared.setLevel(.verbose, isEnabled: previousVerbose)
    appendOutput("lazy counter after filtered .verbose log: \(Self.lazyMessageEvaluationCount) (expect 0). Restored verbose=\(previousVerbose).")
  }

  @objc private func demoConfigProperty() {
    var cfg = FKLogger.shared.config
    let oldPrefix = cfg.prefix
    cfg.prefix = "[ConfigCopy]"
    FKLogger.shared.config = cfg
    FKLogI("Prefix updated via config property")
    cfg.prefix = oldPrefix
    FKLogger.shared.config = cfg
    appendOutput("Temporarily set prefix to [ConfigCopy], logged, then restored to \(oldPrefix).")
  }

  @objc private func demoUpdateConfig() {
    FKLogger.shared.updateConfig { config in
      config.isEnabled = true
      config.includesTimestamp = true
      config.includesLineNumber = true
    }
    FKLogI("updateConfig mutation applied")
    appendOutput("Used updateConfig for atomic in-place edits.")
  }

  @objc private func demoSetLevel() {
    FKLogger.shared.setLevel(.debug, isEnabled: false)
    FKLogD("Debug disabled — this line should not allocate if filtered early")
    FKLogger.shared.setLevel(.debug, isEnabled: true)
    FKLogD("Debug re-enabled")
    appendOutput("Toggled .debug off then on around FKLogD.")
  }

  @objc private func demoApplyDebugPreset() {
    FKLogger.shared.config = .debugDefault
    FKLogI("Applied FKLoggerConfig.debugDefault")
    appendOutput("config = .debugDefault (all levels, file on in preset).")
  }

  @objc private func demoApplyReleasePreset() {
    FKLogger.shared.config = .releaseDefault
    // releaseDefault sets isEnabled=false (global off). Turn logging on to demonstrate level filtering only.
    FKLogger.shared.updateConfig { $0.isEnabled = true }
    FKLogI("Info line — suppressed because release preset keeps enabledLevels=[.error]")
    FKLogE("Error line — allowed under release-style level set")
    appendOutput("Applied .releaseDefault then isEnabled=true: only .error should appear (plus this UI text).")
  }

  @objc private func demoRestoreDemoDefaults() {
    FKLogger.shared.updateConfig { config in
      config.isEnabled = true
      config.enabledLevels = Set(FKLogLevel.allCases)
      config.prefix = "[FKLoggerDemo]"
      config.includesTimestamp = true
      config.includesFileName = true
      config.includesFunctionName = true
      config.includesLineNumber = true
      config.usesColorizedConsole = true
      config.usesEmoji = true
      config.persistsToFile = true
      config.rotatesDaily = true
      config.maxFileSizeInBytes = 2 * 1_048_576
      config.maxStorageSizeInBytes = 20 * 1_048_576
    }
    FKLogI("Restored demo defaults")
    appendOutput("Restored demo-friendly config (prefix, levels, file rotation).")
  }

  @objc private func demoFormatVerbose() {
    FKLogger.shared.updateConfig { config in
      config.includesTimestamp = true
      config.includesFileName = true
      config.includesFunctionName = true
      config.includesLineNumber = true
      config.usesEmoji = true
      config.usesColorizedConsole = true
    }
    FKLogI("Verbose formatting on")
    appendOutput("Timestamp + file + function + line + emoji + ANSI (DEBUG console).")
  }

  @objc private func demoFormatCompact() {
    FKLogger.shared.updateConfig { config in
      config.prefix = "[Compact]"
      config.includesTimestamp = true
      config.includesFileName = false
      config.includesFunctionName = false
      config.includesLineNumber = false
      config.usesEmoji = true
      config.usesColorizedConsole = true
    }
    FKLogI("Compact row", metadata: ["module": "checkout"])
    appendOutput("Compact format: prefix + timestamp + emoji + level + message + metadata.")
  }

  @objc private func demoDumpEncodable() {
    let user = LoggerDemoUser(id: 42, name: "Taylor", tags: ["iOS", "Swift"])
    FKLogger.shared.dumpEncodable(user, level: .debug)
    appendOutput("dumpEncodable → JSON pretty-print with metadata dump=encodable on success.")
  }

  @objc private func demoDumpValueArray() {
    FKLogger.shared.dumpValue(["alpha", "beta", "gamma"], level: .debug)
    appendOutput("dumpValue for Array → JSON list when valid.")
  }

  @objc private func demoDumpValueDict() {
    let payload: [String: Any] = [
      "feature": "logger",
      "enabled": true,
      "retry": 3,
    ]
    FKLogger.shared.dumpValue(payload, level: .debug)
    appendOutput("dumpValue for dictionary → pretty JSON when JSONSerialization accepts it.")
  }

  @objc private func demoEnableFileLogging() {
    FKLogger.shared.updateConfig { config in
      config.persistsToFile = true
      config.rotatesDaily = true
      config.maxFileSizeInBytes = 2 * 1_048_576
      config.maxStorageSizeInBytes = 20 * 1_048_576
    }
    FKLogI("File persistence on", metadata: ["rotation": "daily"])
    FKLogW("Second line to exercise rotation pipeline")
    appendOutput("File logging enabled; wrote sample lines.")
  }

  @objc private func demoListLogFiles() {
    let files = FKLogger.shared.allLogFiles()
    appendOutput("allLogFiles(): \(files.count) file(s)")
    files.prefix(12).forEach { appendOutput("  • \($0.lastPathComponent)") }
    if files.count > 12 {
      appendOutput("  … truncated")
    }
  }

  @objc private func demoFlush() {
    FKLogI("Before flush")
    FKLogger.shared.flushSynchronously()
    appendOutput("flushSynchronously() drained work queue barrier (use before termination).")
  }

  @objc private func demoExportArchive() {
    guard let exportURL = FKLogger.shared.exportLogArchive() else {
      appendOutput("exportLogArchive() returned nil (no log files yet — enable file logging first).")
      return
    }
    let activity = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
    if let popover = activity.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
    }
    present(activity, animated: true)
    appendOutput("Sharing merged archive: \(exportURL.lastPathComponent)")
  }

  @objc private func demoClearPersisted() {
    FKLogger.shared.clearLogFiles()
    appendOutput("clearLogFiles() finished (disk cleared synchronously on file queue).")
  }

  @objc private func demoInstallCrashCapture() {
    FKLogger.shared.installCrashCapture()
    appendOutput("installCrashCapture(): handlers installed once (repeat calls are ignored).")
  }

  @objc private func demoCaptureException() {
    FKLogger.shared.captureException(
      name: "DemoBusinessError",
      reason: "Invalid checkout total",
      metadata: ["screen": "cart", "currency": "USD"]
    )
    appendOutput("captureException → routes as error log with source=custom_exception.")
  }

  @objc private func demoCaptureNetworkError() {
    var request = URLRequest(url: URL(string: "https://api.example.com/v1/orders")!)
    request.httpMethod = "POST"
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: 500,
      httpVersion: nil,
      headerFields: nil
    )
    FKLogger.shared.captureNetwork(
      request: request,
      response: response,
      data: Data("upstream failure".utf8),
      error: NSError(domain: "demo.network", code: 500)
    )
    appendOutput("captureNetwork with 500 + NSError → debug log, source=network.")
  }

  @objc private func demoCaptureNetworkSuccess() {
    var request = URLRequest(url: URL(string: "https://api.example.com/v1/health")!)
    request.httpMethod = "GET"
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )
    FKLogger.shared.captureNetwork(
      request: request,
      response: response,
      data: Data(#"{"status":"ok"}"#.utf8),
      error: nil
    )
    appendOutput("captureNetwork with 200 + JSON bytes.")
  }

  @objc private func demoBuildFlavor() {
    #if DEBUG
    FKLogI("Build flavor: DEBUG — default FKLoggerConfig.default matches debugDefault.")
    appendOutput("#if DEBUG branch documented in log.")
    #else
    FKLogI("Build flavor: RELEASE — default FKLoggerConfig.default matches releaseDefault.")
    appendOutput("#else RELEASE branch documented in log.")
    #endif
  }

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("On-screen log cleared.")
  }

  // MARK: - Output helper

  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let stamp = DateFormatter.loggerDemoFormatter.string(from: Date())
      self.outputView.text.append("[\(stamp)] \(message)\n")
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }
}

private extension DateFormatter {
  static let loggerDemoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}
