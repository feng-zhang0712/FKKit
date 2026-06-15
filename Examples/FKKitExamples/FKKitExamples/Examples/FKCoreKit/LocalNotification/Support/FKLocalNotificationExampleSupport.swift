import FKCoreKit
import Foundation

/// Shared identifiers and helpers for ``FKLocalNotificationManager`` demos.
enum FKLocalNotificationExampleSupport {
  static let manager = FKLocalNotificationManager.shared
  static let categoryIdentifier = "fkkit.example.message"
  /// Demo notification identifier prefix (`fkkit.example.*`).
  static let notificationIdentifierPrefix = "fkkit.example"

  /// Builds a stable demo notification identifier.
  static func identifier(_ suffix: String) -> String {
    "\(notificationIdentifierPrefix).\(suffix)"
  }

  /// Returns whether an identifier belongs to FKKitExamples local-notification demos.
  static func isDemoNotificationIdentifier(_ identifier: String) -> Bool {
    identifier == notificationIdentifierPrefix
      || identifier.hasPrefix(notificationIdentifierPrefix + ".")
  }

  /// Clears persisted demo notifications on cold start so scenarios do not leak across relaunches.
  static func configureAtLaunch() {
    Task {
      await cleanupPersistedDemoNotifications()
    }
  }

  /// Cancels pending and removes delivered notifications whose identifiers match ``notificationIdentifierPrefix``.
  static func cleanupPersistedDemoNotifications() async {
    let pendingIDs = await manager.pendingRequests()
      .map(\.identifier)
      .filter(isDemoNotificationIdentifier)
    if !pendingIDs.isEmpty {
      await manager.cancelPending(withIdentifiers: pendingIDs)
    }

    let deliveredIDs = await manager.deliveredNotifications()
      .map(\.identifier)
      .filter(isDemoNotificationIdentifier)
    if !deliveredIDs.isEmpty {
      await manager.removeDelivered(withIdentifiers: deliveredIDs)
    }

    if await manager.canScheduleNotifications() {
      try? await manager.clearBadge()
    }
  }

  /// Registers the shared message category used by category-action demos.
  static func registerMessageCategory() -> FKLocalNotificationCategory {
    FKLocalNotificationCategory(
      identifier: categoryIdentifier,
      actions: [
        FKLocalNotificationAction(identifier: "mark_read", title: "Mark Read"),
        FKLocalNotificationAction(
          identifier: "snooze",
          title: "Snooze",
          options: .foreground
        ),
      ],
      options: .customDismissAction
    )
  }

  /// Requests notification permission when scheduling is not yet allowed.
  @MainActor
  static func ensureSchedulingAllowed(log: @escaping @MainActor (String) -> Void) async -> Bool {
    if await manager.canScheduleNotifications() {
      log("canScheduleNotifications() → true")
      return true
    }
    log("canScheduleNotifications() → false — requesting via FKPermissions…")
    let result = await FKPermissions.shared.request(
      .notifications,
      prePrompt: FKPermissionPrePrompt(
        title: "Demo Notifications",
        message: "FKKitExamples schedules short local notifications for these interactive demos."
      )
    )
    log("FKPermissions result: status=\(result.status), isGranted=\(result.isGranted)")
    return result.isGranted
  }

  /// Installs the delegate adapter with standard foreground presentation.
  @MainActor
  static func installDelegate(log: @escaping @MainActor (String) -> Void) {
    manager.installDelegate(presentation: .standard)
    log("installDelegate(presentation: [.banner, .list, .sound])")
  }

  /// Wires a response handler that forwards to the demo log.
  @MainActor
  static func wireResponseHandler(log: @escaping @MainActor (String) -> Void) {
    manager.setResponseHandler { response in
      Task { @MainActor in
        log(
          """
          FKLocalNotificationResponse:
            request=\(response.requestIdentifier)
            action=\(response.actionIdentifier)
            isDefault=\(response.isDefaultAction)
            userInfo=\(response.userInfo)
          """
        )
      }
    }
    log("setResponseHandler installed for this demo")
  }

  static func formatError(_ error: Error) -> String {
    if let error = error as? FKLocalNotificationError {
      return "\(error) — \(error.localizedDescription)"
    }
    return String(describing: error)
  }

  static let sampleErrors: [FKLocalNotificationError] = [
    .notAuthorized,
    .invalidTrigger("Repeating interval must be at least 60 seconds."),
    .invalidContent("Title and body cannot both be empty."),
    .attachmentUnavailable("sample.png"),
    .systemError("UNError(1): simulated"),
    .badgeUpdateFailed,
  ]
}
