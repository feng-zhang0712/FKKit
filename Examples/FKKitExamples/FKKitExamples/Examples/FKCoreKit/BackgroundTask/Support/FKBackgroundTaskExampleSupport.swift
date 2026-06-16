import FKCoreKit
import Foundation

/// Shared identifiers and launch wiring for ``FKBackgroundTaskManager`` demos.
enum FKBackgroundTaskExampleSupport {
  static let manager = FKBackgroundTaskManager.shared
  static let identifierPrefix = "fkkit.example"

  static let refreshConfigID = "\(identifierPrefix).refresh.config"
  static let refreshAnalyticsID = "\(identifierPrefix).refresh.analytics"
  static let processingCleanupID = "\(identifierPrefix).processing.cleanup"

  static let plistIdentifiers = [refreshConfigID, refreshAnalyticsID, processingCleanupID]

  /// Registers demo handlers and calls ``FKBackgroundTaskManager/installRegistrations(_:)`` at launch.
  static func configureAtLaunch() {
    do {
      try registerHandlersIfNeeded()
      try manager.installRegistrations([
        .init(identifier: refreshConfigID, kind: .appRefresh),
        .init(identifier: refreshAnalyticsID, kind: .appRefresh),
        .init(identifier: processingCleanupID, kind: .processing),
      ])
      FKLogger.shared.debug("FKBackgroundTaskExampleSupport: registrations installed.")
    } catch {
      FKLogger.shared.debug("FKBackgroundTaskExampleSupport launch registration failed: \(error)")
    }
  }

  private static var didRegisterHandlers = false

  private static func registerHandlersIfNeeded() throws {
    guard !didRegisterHandlers else { return }

    try manager.registerAppRefresh(identifier: refreshConfigID) { handle in
      await FKBackgroundTaskExampleExecutionStore.shared.append(
        "refresh.config handler — isExpired=\(handle.isExpired)"
      )
      try? await Task.sleep(nanoseconds: 300_000_000)
      return !handle.isExpired
    }

    try manager.registerAppRefresh(identifier: refreshAnalyticsID) { handle in
      await FKBackgroundTaskExampleExecutionStore.shared.append(
        "refresh.analytics handler — isExpired=\(handle.isExpired)"
      )
      return !handle.isExpired
    }

    try manager.registerProcessing(identifier: processingCleanupID) { handle in
      await FKBackgroundTaskExampleExecutionStore.shared.append(
        "processing.cleanup handler — isExpired=\(handle.isExpired)"
      )
      return !handle.isExpired
    }

    didRegisterHandlers = true
  }

  static func formatError(_ error: Error) -> String {
    if let error = error as? FKBackgroundTaskError {
      return "\(error) — \(error.localizedDescription)"
    }
    return String(describing: error)
  }

  static func formatPending(_ summaries: [FKBackgroundTaskPendingSummary]) -> String {
    guard !summaries.isEmpty else { return "(none)" }
    return summaries.map { summary in
      var parts = ["\(summary.identifier) (\(summary.kind))"]
      if let date = summary.earliestBeginDate {
        parts.append("earliest=\(date)")
      }
      if summary.requiresNetworkConnectivity {
        parts.append("network")
      }
      if summary.requiresExternalPower {
        parts.append("externalPower")
      }
      return parts.joined(separator: ", ")
    }.joined(separator: "\n")
  }

  static let sampleErrors: [FKBackgroundTaskError] = [
    .unregisteredIdentifier("com.example.missing"),
    .duplicateRegistration(refreshConfigID),
    .identifierNotPermitted("com.example.not.in.plist"),
    .schedulingFailed(code: 4),
    .backgroundWorkUnavailable,
    .alreadyInstalled,
    .notInstalled,
  ]

  static let launchSnippet = """
    // AppDelegate.application(_:didFinishLaunchingWithOptions:) — before return
    try FKBackgroundTaskManager.shared.registerAppRefresh(identifier: refreshID) { handle in
      guard !handle.isExpired else { return false }
      return true
    }
    try FKBackgroundTaskManager.shared.installRegistrations([
      .init(identifier: refreshID, kind: .appRefresh),
    ])
    """
}
