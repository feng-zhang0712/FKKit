import Foundation
@preconcurrency import UserNotifications

#if os(iOS)

/// In-memory ``FKLocalNotificationScheduling`` implementation for tests and FKKitExamples.
public final class FKMockLocalNotificationScheduler: FKLocalNotificationScheduling, @unchecked Sendable {
  private let stateQueue = DispatchQueue(label: "com.fkkit.local-notification.mock")
  private var stored: [String: FKLocalNotificationRequest] = [:]
  private var delivered: [String: FKLocalNotificationRequest] = [:]

  /// Scheduled requests keyed by identifier (most recent schedule wins).
  public var scheduled: [FKLocalNotificationRequest] {
    stateQueue.sync { Array(stored.values) }
  }

  /// Error thrown on the next schedule attempt when set.
  public var shouldThrow: FKLocalNotificationError? {
    get { stateQueue.sync { _shouldThrow } }
    set { stateQueue.sync { _shouldThrow = newValue } }
  }

  /// When `false`, ``schedule(_:)`` throws ``FKLocalNotificationError/notAuthorized``.
  public var authorizationGranted: Bool {
    get { stateQueue.sync { _authorizationGranted } }
    set { stateQueue.sync { _authorizationGranted = newValue } }
  }

  /// Optional response handler for simulating user taps in Examples.
  public var responseHandler: FKLocalNotificationResponseHandler? {
    get { stateQueue.sync { _responseHandler } }
    set { stateQueue.sync { _responseHandler = newValue } }
  }

  private var _shouldThrow: FKLocalNotificationError?
  private var _authorizationGranted = true
  private var _responseHandler: FKLocalNotificationResponseHandler?

  /// Creates an empty mock scheduler.
  public init() {}

  /// Schedules a request in memory when ``authorizationGranted`` is true.
  public func schedule(_ request: FKLocalNotificationRequest) async throws {
    let result: Result<Void, FKLocalNotificationError> = stateQueue.sync {
      if let error = _shouldThrow {
        return .failure(error)
      }
      guard _authorizationGranted else {
        return .failure(.notAuthorized)
      }
      do {
        try FKLocalNotificationRequestMapper.validateRequest(request)
      } catch let error as FKLocalNotificationError {
        return .failure(error)
      } catch {
        return .failure(.systemError(error.localizedDescription))
      }
      stored[request.identifier] = request
      return .success(())
    }
    try result.get()
  }

  /// Schedules multiple requests; throws on the first failure.
  public func schedule(_ requests: [FKLocalNotificationRequest]) async throws {
    for request in requests {
      try await schedule(request)
    }
  }

  /// Removes a pending request from memory.
  public func cancelPending(withIdentifier identifier: String) async {
    stateQueue.sync { stored[identifier] = nil }
  }

  /// Removes multiple pending requests from memory.
  public func cancelPending(withIdentifiers identifiers: [String]) async {
    stateQueue.sync {
      identifiers.forEach { stored[$0] = nil }
    }
  }

  /// Clears all pending requests from memory.
  public func cancelAllPending() async {
    stateQueue.sync { stored.removeAll() }
  }

  /// Removes a delivered notification from memory.
  public func removeDelivered(withIdentifier identifier: String) async {
    stateQueue.sync { delivered[identifier] = nil }
  }

  /// Removes multiple delivered notifications from memory.
  public func removeDelivered(withIdentifiers identifiers: [String]) async {
    stateQueue.sync {
      identifiers.forEach { delivered[$0] = nil }
    }
  }

  /// Clears all delivered notifications from memory.
  public func removeAllDelivered() async {
    stateQueue.sync { delivered.removeAll() }
  }

  /// Simulates a user tap on a scheduled or delivered notification.
  public func simulateResponse(
    requestIdentifier: String,
    actionIdentifier: String = UNNotificationDefaultActionIdentifier,
    isDefaultAction: Bool = true
  ) {
    let snapshot = stateQueue.sync { () -> (FKLocalNotificationRequest?, FKLocalNotificationResponseHandler?) in
      let request = stored[requestIdentifier] ?? delivered[requestIdentifier]
      return (request, _responseHandler)
    }

    guard let request = snapshot.0, let handler = snapshot.1 else { return }
    let response = FKLocalNotificationResponse(
      requestIdentifier: requestIdentifier,
      actionIdentifier: actionIdentifier,
      userInfo: request.content.userInfo,
      isDefaultAction: isDefaultAction
    )
    let deliver = { handler(response) }
    if Thread.isMainThread {
      deliver()
    } else {
      DispatchQueue.main.async(execute: deliver)
    }
  }

  /// Marks a request as delivered (moves from pending to delivered in memory).
  public func simulateDelivery(identifier: String) {
    stateQueue.sync {
      if let request = stored.removeValue(forKey: identifier) {
        delivered[identifier] = request
      }
    }
  }
}

#endif
