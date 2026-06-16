import Foundation

/// Notification sound configuration.
public enum FKLocalNotificationSound: Sendable, Hashable {
  /// System default notification sound.
  case `default`

  /// Silent notification (no sound).
  case none

  /// Named sound file in the app bundle or Library/Sounds.
  case named(String)
}

/// Interruption level for notification delivery priority (iOS 15+).
public enum FKNotificationInterruptionLevel: Sendable, Hashable {
  /// Passive delivery; does not light the screen.
  case passive

  /// Active delivery; may light the screen.
  case active

  /// Time Sensitive; requires Time Sensitive Notifications capability.
  case timeSensitive

  /// Critical; requires Critical Alerts entitlement.
  case critical
}

/// Local notification content model.
public struct FKLocalNotificationContent: Sendable, Hashable {
  /// Primary notification title.
  public var title: String

  /// Primary notification body.
  public var body: String

  /// Optional subtitle displayed below the title.
  public var subtitle: String?

  /// Sound played when the notification is delivered.
  public var sound: FKLocalNotificationSound

  /// Optional app icon badge number applied on delivery.
  public var badge: Int?

  /// String-only payload for Sendable safety; JSON-encode complex values as strings.
  public var userInfo: [String: String]

  /// Thread identifier for notification grouping.
  public var threadIdentifier: String?

  /// Target content identifier for Notification Content extensions.
  public var targetContentIdentifier: String?

  /// Optional interruption level (iOS 15+).
  public var interruptionLevel: FKNotificationInterruptionLevel?

  /// Optional relevance score hint (iOS 15+, 0.0–1.0).
  public var relevanceScore: Double?

  /// Creates notification content.
  public init(
    title: String,
    body: String,
    subtitle: String? = nil,
    sound: FKLocalNotificationSound = .default,
    badge: Int? = nil,
    userInfo: [String: String] = [:],
    threadIdentifier: String? = nil,
    targetContentIdentifier: String? = nil,
    interruptionLevel: FKNotificationInterruptionLevel? = nil,
    relevanceScore: Double? = nil
  ) {
    self.title = title
    self.body = body
    self.subtitle = subtitle
    self.sound = sound
    self.badge = badge
    self.userInfo = userInfo
    self.threadIdentifier = threadIdentifier
    self.targetContentIdentifier = targetContentIdentifier
    self.interruptionLevel = interruptionLevel
    self.relevanceScore = relevanceScore
  }
}
