#if os(iOS)
import Foundation
@preconcurrency import UserNotifications

enum FKLocalNotificationRequestMapper {
  static let pendingRequestLimit = 64

  static func validateRequest(_ request: FKLocalNotificationRequest) throws {
    let trimmedIdentifier = request.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedIdentifier.isEmpty else {
      throw FKLocalNotificationError.invalidContent("Request identifier cannot be empty.")
    }
    try validateContent(request.content)
    try FKLocalNotificationTriggerMapper.validate(request.trigger)
  }

  static func validateContent(_ content: FKLocalNotificationContent) throws {
    let trimmedTitle = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBody = content.body.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else {
      throw FKLocalNotificationError.invalidContent("Title and body cannot both be empty.")
    }
  }

  static func makeUNRequest(from request: FKLocalNotificationRequest) throws -> UNNotificationRequest {
    try validateRequest(request)

    let content = makeUNContent(from: request.content, categoryIdentifier: request.categoryIdentifier)
    let trigger = try FKLocalNotificationTriggerMapper.makeUNTrigger(from: request.trigger)
    return UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
  }

  static func makeUNContent(
    from content: FKLocalNotificationContent,
    categoryIdentifier: String?
  ) -> UNMutableNotificationContent {
    let unContent = UNMutableNotificationContent()
    unContent.title = content.title
    unContent.body = content.body
    if let subtitle = content.subtitle {
      unContent.subtitle = subtitle
    }
    unContent.sound = mapSound(content.sound)
    if let badge = content.badge {
      unContent.badge = NSNumber(value: badge)
    }
    unContent.userInfo = content.userInfo
    if let threadIdentifier = content.threadIdentifier {
      unContent.threadIdentifier = threadIdentifier
    }
    if let targetContentIdentifier = content.targetContentIdentifier {
      unContent.targetContentIdentifier = targetContentIdentifier
    }
    if let interruptionLevel = content.interruptionLevel {
      unContent.interruptionLevel = mapInterruptionLevel(interruptionLevel)
    }
    if let relevanceScore = content.relevanceScore {
      unContent.relevanceScore = relevanceScore
    }
    if let categoryIdentifier {
      unContent.categoryIdentifier = categoryIdentifier
    }
    return unContent
  }

  static func makeFKContent(from unContent: UNNotificationContent) -> FKLocalNotificationContent {
    let userInfo = stringUserInfo(from: unContent.userInfo)
    let sound: FKLocalNotificationSound = unContent.sound == nil ? .none : .default

    return FKLocalNotificationContent(
      title: unContent.title,
      body: unContent.body,
      subtitle: unContent.subtitle.isEmpty ? nil : unContent.subtitle,
      sound: sound,
      badge: unContent.badge?.intValue,
      userInfo: userInfo,
      threadIdentifier: unContent.threadIdentifier.isEmpty ? nil : unContent.threadIdentifier,
      targetContentIdentifier: unContent.targetContentIdentifier,
      interruptionLevel: mapInterruptionLevel(unContent.interruptionLevel),
      relevanceScore: unContent.relevanceScore == 0 ? nil : unContent.relevanceScore
    )
  }

  static func makePendingSummary(from request: UNNotificationRequest) -> FKLocalNotificationPendingSummary {
    FKLocalNotificationPendingSummary(
      identifier: request.identifier,
      content: makeFKContent(from: request.content),
      triggerDescription: FKLocalNotificationTriggerMapper.triggerDescription(for: request.trigger)
    )
  }

  static func makeDeliveredSummary(from notification: UNNotification) -> FKLocalNotificationDeliveredSummary {
    FKLocalNotificationDeliveredSummary(
      identifier: notification.request.identifier,
      content: makeFKContent(from: notification.request.content),
      deliveryDate: notification.date
    )
  }

  static func makeUNCategories(from categories: [FKLocalNotificationCategory]) -> Set<UNNotificationCategory> {
    Set(
      categories.map { category in
        let actions = category.actions.map { action in
          UNNotificationAction(
            identifier: action.identifier,
            title: action.title,
            options: mapActionOptions(action.options)
          )
        }
        return UNNotificationCategory(
          identifier: category.identifier,
          actions: actions,
          intentIdentifiers: category.intentIdentifiers,
          options: mapCategoryOptions(category.options)
        )
      }
    )
  }

  private static func mapSound(_ sound: FKLocalNotificationSound) -> UNNotificationSound? {
    switch sound {
    case .default:
      return .default
    case .none:
      return nil
    case let .named(name):
      return UNNotificationSound(named: UNNotificationSoundName(rawValue: name))
    }
  }

  private static func mapInterruptionLevel(_ level: FKNotificationInterruptionLevel) -> UNNotificationInterruptionLevel {
    switch level {
    case .passive:
      return .passive
    case .active:
      return .active
    case .timeSensitive:
      return .timeSensitive
    case .critical:
      return .critical
    }
  }

  private static func mapInterruptionLevel(_ level: UNNotificationInterruptionLevel) -> FKNotificationInterruptionLevel? {
    switch level {
    case .passive:
      return .passive
    case .active:
      return .active
    case .timeSensitive:
      return .timeSensitive
    case .critical:
      return .critical
    @unknown default:
      return nil
    }
  }

  private static func mapActionOptions(_ options: FKLocalNotificationActionOptions) -> UNNotificationActionOptions {
    var unOptions: UNNotificationActionOptions = []
    if options.contains(.authenticationRequired) { unOptions.insert(.authenticationRequired) }
    if options.contains(.destructive) { unOptions.insert(.destructive) }
    if options.contains(.foreground) { unOptions.insert(.foreground) }
    return unOptions
  }

  private static func mapCategoryOptions(_ options: FKLocalNotificationCategoryOptions) -> UNNotificationCategoryOptions {
    var unOptions: UNNotificationCategoryOptions = []
    if options.contains(.customDismissAction) { unOptions.insert(.customDismissAction) }
    if options.contains(.allowInCarPlay) { unOptions.insert(.allowInCarPlay) }
    if options.contains(.hiddenPreviewsShowTitle) { unOptions.insert(.hiddenPreviewsShowTitle) }
    if options.contains(.hiddenPreviewsShowSubtitle) { unOptions.insert(.hiddenPreviewsShowSubtitle) }
    return unOptions
  }

  private static func stringUserInfo(from userInfo: [AnyHashable: Any]) -> [String: String] {
    var output: [String: String] = [:]
    for (key, value) in userInfo {
      guard let stringKey = key as? String else { continue }
      if let stringValue = value as? String {
        output[stringKey] = stringValue
      } else {
        output[stringKey] = String(describing: value)
      }
    }
    return output
  }
}

#endif
