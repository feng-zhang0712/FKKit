import CoreLocation
import Foundation

#if os(iOS)

/// Handles all Core Location permission flows under a unified permission contract.
///
/// This handler supports:
/// - `when in use`
/// - `always`
/// - temporary full-accuracy upgrade on iOS 14+
@MainActor
final class FKLocationPermissionHandler: NSObject, FKPermissionHandling, @preconcurrency CLLocationManagerDelegate {
  /// Target permission kind bound to this handler instance.
  let kind: FKPermissionKind
  /// Cached manager used during interactive authorization requests.
  private var manager: CLLocationManager?
  /// Continuation resumed when an authorization callback is received.
  private var continuation: CheckedContinuation<FKPermissionResult, Never>?

  init(kind: FKPermissionKind) {
    self.kind = kind
  }

  /// Reads current location authorization state without prompting.
  func currentStatus() async -> FKPermissionStatus {
    let status = CLLocationManager.authorizationStatus()
    switch kind {
    case .locationWhenInUse:
      return mapWhenInUse(status)
    case .locationAlways:
      return mapAlways(status)
    case .locationTemporaryFullAccuracy:
      return mapTemporaryAccuracy(status)
    default:
      return .restricted
    }
  }

  /// Requests location authorization according to the configured `kind`.
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    if kind == .locationTemporaryFullAccuracy {
      return await requestTemporaryAccuracy(request)
    }

    let current = await currentStatus()
    if current != .notDetermined {
      return FKPermissionResult(kind: kind, status: current)
    }

    // Keep waiting until Core Location leaves the undecided state.
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      let manager = CLLocationManager()
      manager.delegate = self
      self.manager = manager
      if self.kind == .locationAlways {
        manager.requestAlwaysAuthorization()
      } else {
        manager.requestWhenInUseAuthorization()
      }
    }
  }

  /// Delegate callback invoked by Core Location when authorization changes.
  ///
  /// The method is nonisolated to satisfy delegate requirements; execution hops back to
  /// the main actor before touching actor-isolated state.
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      guard let continuation = self.continuation else { return }
      let status = self.mapSystemStatus(CLLocationManager.authorizationStatus())
      if status == .notDetermined {
        return
      }
      self.continuation = nil
      self.manager = nil
      continuation.resume(returning: FKPermissionResult(kind: self.kind, status: status))
    }
  }

  /// Requests temporary full-accuracy upgrade after base location permission is granted.
  private func requestTemporaryAccuracy(_ request: FKPermissionRequest) async -> FKPermissionResult {
    guard #available(iOS 14.0, *) else {
      return FKPermissionResult(kind: kind, status: .deviceDisabled, error: .unavailable)
    }

    // Temporary accuracy can only be requested after basic location access is granted.
    let baseStatus = CLLocationManager.authorizationStatus()
    guard baseStatus == .authorizedWhenInUse || baseStatus == .authorizedAlways else {
      return FKPermissionResult(kind: kind, status: .denied)
    }

    // Read current accuracy on the main actor; no delegate is used for this flow.
    let manager = CLLocationManager()

    // Skip request if already at full accuracy.
    if manager.accuracyAuthorization == .fullAccuracy {
      return FKPermissionResult(kind: kind, status: .authorized)
    }

    // A matching key must exist under NSLocationTemporaryUsageDescriptionDictionary.
    let key = request.temporaryLocationPurposeKey ?? "FKLocationTemporaryFullAccuracyPurpose"
    do {
      // Use the Objective-C completion API on the main queue instead of the async `throws`
      // overload. Under `SWIFT_STRICT_CONCURRENCY=complete` (e.g. Xcode 16.4), awaiting the async
      // overload is diagnosed as sending a `MainActor`-isolated `CLLocationManager` into a
      // nonisolated async SDK method.
      try await Self.requestTemporaryFullAccuracyUsingCompletion(purposeKey: key)
    } catch {
      return FKPermissionResult(kind: kind, status: .denied, error: .custom(error.localizedDescription))
    }

    // Re-check current accuracy after the system request returns (global state).
    let accuracy = CLLocationManager().accuracyAuthorization
    let status: FKPermissionStatus = accuracy == .fullAccuracy ? .authorized : .denied
    return FKPermissionResult(kind: kind, status: status)
  }

  /// Bridges `requestTemporaryFullAccuracyAuthorizationWithPurposeKey:completion:` to async
  /// without crossing Swift 6 strict isolation on the async-imported overload.
  private static func requestTemporaryFullAccuracyUsingCompletion(purposeKey: String) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      DispatchQueue.main.async {
        let requestManager = CLLocationManager()
        requestManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume()
          }
        }
      }
    }
  }

  /// Maps system authorization status to this handler's current permission kind.
  private func mapSystemStatus(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch kind {
    case .locationWhenInUse:
      return mapWhenInUse(status)
    case .locationAlways:
      return mapAlways(status)
    case .locationTemporaryFullAccuracy:
      return mapTemporaryAccuracy(status)
    default:
      return .restricted
    }
  }

  /// Maps Core Location status for `when in use` capability.
  private func mapWhenInUse(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorizedWhenInUse, .authorizedAlways: return .authorized
    @unknown default: return .restricted
    }
  }

  /// Maps Core Location status for `always` capability.
  private func mapAlways(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied, .authorizedWhenInUse: return .denied
    case .authorizedAlways: return .authorized
    @unknown default: return .restricted
    }
  }

  /// Maps temporary full-accuracy capability into unified permission status.
  private func mapTemporaryAccuracy(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorizedWhenInUse, .authorizedAlways:
      if #available(iOS 14.0, *) {
        let accuracy = CLLocationManager().accuracyAuthorization
        return accuracy == .fullAccuracy ? .authorized : .limited
      }
      return .authorized
    @unknown default: return .restricted
    }
  }
}

#endif
