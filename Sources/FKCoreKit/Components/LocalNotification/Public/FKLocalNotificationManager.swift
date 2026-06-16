#if os(iOS)
import Foundation

/// Default ``FKLocalNotificationScheduling`` implementation backed by `UNUserNotificationCenter`.
///
/// Request notification permission via ``FKPermissions`` before scheduling — this manager never prompts.
public final class FKLocalNotificationManager: FKLocalNotificationScheduling, @unchecked Sendable {
  /// Shared singleton using default configuration.
  public static let shared = FKLocalNotificationManager()

  private let notificationCenter: UserNotificationCenterType
  private let configuration: FKLocalNotificationManagerConfiguration
  private let stateQueue = DispatchQueue(label: "com.fkkit.local-notification.manager")
  private var responseHandler: FKLocalNotificationResponseHandler?
  private var deeplinkRouter: (@Sendable (URL) -> Bool)?
  private var delegateAdapter: FKLocalNotificationCenterDelegateAdapter?
  private var registeredCategoryIdentifiers: Set<String> = []

  /// Creates a manager with optional configuration.
  public init(configuration: FKLocalNotificationManagerConfiguration = .default) {
    self.notificationCenter = SystemUserNotificationCenter()
    self.configuration = configuration
    if configuration.automaticallyInstallDelegate {
      installDelegate(presentation: configuration.defaultPresentation)
    }
  }

  init(
    notificationCenter: UserNotificationCenterType,
    configuration: FKLocalNotificationManagerConfiguration
  ) {
    self.notificationCenter = notificationCenter
    self.configuration = configuration
    if configuration.automaticallyInstallDelegate {
      installDelegate(presentation: configuration.defaultPresentation)
    }
  }

  // MARK: - Authorization

  /// Returns whether scheduling is allowed without prompting.
  ///
  /// `true` when ``FKPermissions`` reports `.authorized`, `.provisional`, or `.ephemeral` for notifications.
  public func canScheduleNotifications() async -> Bool {
    let status = await FKPermissions.shared.status(for: .notifications)
    switch status {
    case .authorized, .provisional, .ephemeral:
      return true
    case .notDetermined, .denied, .restricted, .limited, .deviceDisabled:
      return false
    }
  }

  // MARK: - FKLocalNotificationScheduling

  /// Schedules a single local notification after authorization and validation checks.
  public func schedule(_ request: FKLocalNotificationRequest) async throws {
    guard await canScheduleNotifications() else {
      logSchedulingFailure(FKLocalNotificationError.notAuthorized)
      throw FKLocalNotificationError.notAuthorized
    }

    await warnIfCategoryUnregistered(request.categoryIdentifier)

    do {
      let unRequest = try FKLocalNotificationRequestMapper.makeUNRequest(from: request)
      try await notificationCenter.add(unRequest)
      await warnIfPendingLimitReached()
    } catch let error as FKLocalNotificationError {
      logSchedulingFailure(error)
      throw error
    } catch {
      let mapped = FKLocalNotificationErrorMapper.map(error)
      logSchedulingFailure(mapped)
      throw mapped
    }
  }

  /// Schedules multiple requests sequentially; throws on the first failure.
  public func schedule(_ requests: [FKLocalNotificationRequest]) async throws {
    for request in requests {
      try await schedule(request)
    }
  }

  /// Cancels a pending notification by identifier.
  public func cancelPending(withIdentifier identifier: String) async {
    await notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
  }

  /// Cancels multiple pending notifications by identifier.
  public func cancelPending(withIdentifiers identifiers: [String]) async {
    guard !identifiers.isEmpty else { return }
    await notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
  }

  /// Cancels all pending local notifications for this app (not limited to FKKit-scheduled identifiers).
  public func cancelAllPending() async {
    await notificationCenter.removeAllPendingNotificationRequests()
  }

  /// Removes a delivered notification from Notification Center by identifier.
  public func removeDelivered(withIdentifier identifier: String) async {
    await notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
  }

  /// Removes multiple delivered notifications from Notification Center by identifier.
  public func removeDelivered(withIdentifiers identifiers: [String]) async {
    guard !identifiers.isEmpty else { return }
    await notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
  }

  /// Removes all delivered notifications from Notification Center for this app.
  public func removeAllDelivered() async {
    await notificationCenter.removeAllDeliveredNotifications()
  }

  // MARK: - Query

  /// Returns summaries of all pending notification requests.
  public func pendingRequests() async -> [FKLocalNotificationPendingSummary] {
    await notificationCenter.pendingNotificationRequests()
  }

  /// Returns summaries of all delivered notifications currently in Notification Center.
  public func deliveredNotifications() async -> [FKLocalNotificationDeliveredSummary] {
    await notificationCenter.deliveredNotifications()
  }

  // MARK: - Badge

  /// Sets the app icon badge count (iOS 16+ API when available).
  public func setBadgeCount(_ count: Int) async throws {
    do {
      try await notificationCenter.setBadgeCount(count)
    } catch {
      throw FKLocalNotificationError.badgeUpdateFailed
    }
  }

  /// Clears the app icon badge (sets count to zero).
  public func clearBadge() async throws {
    try await setBadgeCount(0)
  }

  // MARK: - Categories

  /// Registers notification categories and their action buttons.
  ///
  /// Call once at app launch; re-registering replaces existing categories with the same identifiers.
  public func registerCategories(_ categories: [FKLocalNotificationCategory]) async throws {
    let unCategories = FKLocalNotificationRequestMapper.makeUNCategories(from: categories)
    await notificationCenter.setNotificationCategories(unCategories)
    stateQueue.sync {
      categories.forEach { registeredCategoryIdentifiers.insert($0.identifier) }
    }
  }

  /// Returns identifiers of categories registered through this manager instance.
  public func registeredCategoryIdentifiers() async -> Set<String> {
    let local = stateQueue.sync { registeredCategoryIdentifiers }

    let systemIDs = await notificationCenter.notificationCategoryIdentifiers()
    return local.union(systemIDs)
  }

  // MARK: - Delegate & Response

  /// Installs the delegate adapter as `UNUserNotificationCenter.current().delegate`.
  ///
  /// Call once from `AppDelegate` or scene delegate. This **replaces** any existing delegate (v1 behavior).
  public func installDelegate(
    presentation: FKLocalNotificationPresentationOptions? = nil
  ) {
    let adapter = delegateAdapter ?? FKLocalNotificationCenterDelegateAdapter()
    adapter.presentationOptions = presentation ?? configuration.defaultPresentation
    adapter.routeDeeplinkBeforeResponseHandler = configuration.routeDeeplinkBeforeResponseHandler
    syncHandlers(to: adapter)
    delegateAdapter = adapter
    notificationCenter.delegate = adapter
  }

  /// Thread-safe setter for notification tap/action callbacks (invoked on the main queue).
  public func setResponseHandler(_ handler: FKLocalNotificationResponseHandler?) {
    stateQueue.sync { responseHandler = handler }
    if let delegateAdapter {
      delegateAdapter.setResponseHandler(handler)
    }
  }

  /// Thread-safe setter for optional deeplink routing on notification tap.
  public func setDeeplinkRouter(_ router: (@Sendable (URL) -> Bool)?) {
    stateQueue.sync { deeplinkRouter = router }
    if let delegateAdapter {
      delegateAdapter.setDeeplinkRouter(router)
    }
  }

  // MARK: - Private

  private func syncHandlers(to adapter: FKLocalNotificationCenterDelegateAdapter) {
    let snapshot = stateQueue.sync { (responseHandler, deeplinkRouter) }
    adapter.setResponseHandler(snapshot.0)
    adapter.setDeeplinkRouter(snapshot.1)
  }

  private func warnIfCategoryUnregistered(_ categoryIdentifier: String?) async {
    guard let categoryIdentifier else { return }
    let locallyRegistered = stateQueue.sync { registeredCategoryIdentifiers.contains(categoryIdentifier) }
    if locallyRegistered { return }

    let systemIDs = await notificationCenter.notificationCategoryIdentifiers()
    guard !systemIDs.contains(categoryIdentifier) else { return }

    FKLogger.shared.debug(
      "Scheduling notification with unregistered category '\(categoryIdentifier)'; custom actions will not appear."
    )
  }

  private func warnIfPendingLimitReached() async {
    let count = await notificationCenter.pendingNotificationRequests().count
    let limit = FKLocalNotificationRequestMapper.pendingRequestLimit
    if count >= limit {
      FKLogger.shared.debug(
        "Pending local notification count (\(count)) reached iOS limit (~\(limit)); additional requests may be silently dropped."
      )
    }
  }

  private func logSchedulingFailure(_ error: FKLocalNotificationError) {
    guard configuration.logSchedulingFailures else { return }
    FKLogger.shared.debug("Local notification scheduling failed: \(error.localizedDescription)")
  }
}

#endif
