import FKCoreKit
import UIKit

/// Demonstrates `FKPluggableLogging`, `FKPluggableLogLevel`, and protocol extension helpers.
final class FKPluggableLoggingExampleViewController: FKPluggableExampleBaseViewController {

  private let logger = DemoPluggableLogger()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Logging"
    logger.onLog = { [weak self] line in
      Task { @MainActor in self?.appendOutput(line) }
    }

    addActionButton("1) Log all FKPluggableLogLevel values") { [weak self] in
      guard let self else { return }
      for level in FKPluggableLogLevel.allCases {
        logger.log(level: level, "Sample \(level) message", file: #fileID, function: #function, line: #line)
      }
    }
    addActionButton("2) logger.debug() helper") { [weak self] in
      self?.logger.debug("Debug helper invoked")
    }
    addActionButton("3) logger.info() helper") { [weak self] in
      self?.logger.info("Info helper invoked")
    }
    addActionButton("4) logger.error() helper") { [weak self] in
      self?.logger.error("Error helper invoked")
    }
    addActionButton("5) Raise minimumLevel to .warning") { [weak self] in
      self?.logger.minimumLevel = .warning
      self?.appendOutput("minimumLevel = .warning (debug/info suppressed)")
      self?.logger.debug("This debug line should NOT appear")
      self?.logger.error("This error line SHOULD appear")
    }
    addActionButton("6) Reset minimumLevel to .debug") { [weak self] in
      self?.logger.minimumLevel = .debug
      self?.appendOutput("minimumLevel reset to .debug")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }
}
