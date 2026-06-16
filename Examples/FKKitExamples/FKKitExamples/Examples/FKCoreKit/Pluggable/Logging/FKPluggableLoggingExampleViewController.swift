import FKCoreKit
import UIKit

/// Demonstrates ``FKPluggableLogging`` via ``FKLoggerPluggableAdapter`` and ``FKMockPluggableLogger``.
final class FKPluggableLoggingExampleViewController: FKPluggableExampleBaseViewController {

  private let mockLogger = FKMockPluggableLogger()
  private var loggerAdapter = FKLoggerPluggableAdapter()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Logging"

    addActionButton("1) FKMockPluggableLogger — all levels") { [weak self] in
      guard let self else { return }
      mockLogger.reset()
      for level in FKPluggableLogLevel.allCases {
        mockLogger.log(level: level, "Sample \(level) message", file: #fileID, function: #function, line: #line)
      }
      appendOutput("Captured \(mockLogger.capturedEntries().count) entries")
      mockLogger.capturedEntries().forEach { appendOutput("[\($0.level)] \($0.message)") }
    }
    addActionButton("2) FKLoggerPluggableAdapter → FKLogger") { [weak self] in
      self?.loggerAdapter.info("Pluggable adapter bridged to FKLogger")
      self?.appendOutput("Emitted via FKLoggerPluggableAdapter (see Xcode console in DEBUG)")
    }
    addActionButton("3) Raise adapter minimumLevel to .warning") { [weak self] in
      self?.loggerAdapter.minimumLevel = .warning
      self?.appendOutput("minimumLevel = .warning")
      self?.loggerAdapter.debug("Suppressed debug line")
      self?.loggerAdapter.error("Visible error line")
    }
    addActionButton("4) Reset adapter minimumLevel to .debug") { [weak self] in
      self?.loggerAdapter.minimumLevel = .debug
      self?.appendOutput("minimumLevel reset to .debug")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }
}
