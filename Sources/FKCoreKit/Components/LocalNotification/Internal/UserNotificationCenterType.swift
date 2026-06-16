#if os(iOS)
import Foundation
@preconcurrency import UserNotifications
import UIKit

/// Abstraction over `UNUserNotificationCenter` for testing and dependency injection.
protocol UserNotificationCenterType: AnyObject, Sendable {
  var delegate: UNUserNotificationCenterDelegate? { get set }

  func add(_ request: UNNotificationRequest) async throws
  func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async
  func removeAllPendingNotificationRequests() async
  func removeDeliveredNotifications(withIdentifiers identifiers: [String]) async
  func removeAllDeliveredNotifications() async
  func pendingNotificationRequests() async -> [FKLocalNotificationPendingSummary]
  func deliveredNotifications() async -> [FKLocalNotificationDeliveredSummary]
  func setNotificationCategories(_ categories: Set<UNNotificationCategory>) async
  func notificationCategoryIdentifiers() async -> Set<String>
  func setBadgeCount(_ count: Int) async throws
}

/// Production `UNUserNotificationCenter` wrapper.
final class SystemUserNotificationCenter: UserNotificationCenterType, @unchecked Sendable {
  private let center = UNUserNotificationCenter.current()

  var delegate: UNUserNotificationCenterDelegate? {
    get { center.delegate }
    set { center.delegate = newValue }
  }

  func add(_ request: UNNotificationRequest) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      center.add(request) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }

  func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
  }

  func removeAllPendingNotificationRequests() async {
    center.removeAllPendingNotificationRequests()
  }

  func removeDeliveredNotifications(withIdentifiers identifiers: [String]) async {
    center.removeDeliveredNotifications(withIdentifiers: identifiers)
  }

  func removeAllDeliveredNotifications() async {
    center.removeAllDeliveredNotifications()
  }

  func pendingNotificationRequests() async -> [FKLocalNotificationPendingSummary] {
    await withCheckedContinuation { continuation in
      center.getPendingNotificationRequests { requests in
        let summaries = requests.map(FKLocalNotificationRequestMapper.makePendingSummary(from:))
        continuation.resume(returning: summaries)
      }
    }
  }

  func deliveredNotifications() async -> [FKLocalNotificationDeliveredSummary] {
    await withCheckedContinuation { continuation in
      center.getDeliveredNotifications { notifications in
        let summaries = notifications.map(FKLocalNotificationRequestMapper.makeDeliveredSummary(from:))
        continuation.resume(returning: summaries)
      }
    }
  }

  func setNotificationCategories(_ categories: Set<UNNotificationCategory>) async {
    center.setNotificationCategories(categories)
  }

  func notificationCategoryIdentifiers() async -> Set<String> {
    await withCheckedContinuation { continuation in
      center.getNotificationCategories { categories in
        continuation.resume(returning: Set(categories.map(\.identifier)))
      }
    }
  }

  func setBadgeCount(_ count: Int) async throws {
    if #available(iOS 16.0, *) {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        center.setBadgeCount(count) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume()
          }
        }
      }
    } else {
      try await MainActor.run {
        UIApplication.shared.applicationIconBadgeNumber = count
      }
    }
  }
}

#endif
