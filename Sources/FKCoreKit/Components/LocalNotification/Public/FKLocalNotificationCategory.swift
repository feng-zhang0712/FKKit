import Foundation

/// Options for a notification category.
public struct FKLocalNotificationCategoryOptions: OptionSet, Sendable, Hashable {
  /// Raw option bitmask.
  public let rawValue: UInt

  /// Creates options from a raw value.
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

  /// Include custom dismiss action handling.
  public static let customDismissAction = FKLocalNotificationCategoryOptions(rawValue: 1 << 0)

  /// Allow actions while connected to CarPlay.
  public static let allowInCarPlay = FKLocalNotificationCategoryOptions(rawValue: 1 << 1)

  /// Show title in hidden notification previews.
  public static let hiddenPreviewsShowTitle = FKLocalNotificationCategoryOptions(rawValue: 1 << 2)

  /// Show subtitle in hidden notification previews.
  public static let hiddenPreviewsShowSubtitle = FKLocalNotificationCategoryOptions(rawValue: 1 << 3)
}

/// Options for a notification action button.
public struct FKLocalNotificationActionOptions: OptionSet, Sendable, Hashable {
  /// Raw option bitmask.
  public let rawValue: UInt

  /// Creates options from a raw value.
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

  /// Require authentication before performing the action.
  public static let authenticationRequired = FKLocalNotificationActionOptions(rawValue: 1 << 0)

  /// Destructive action styling.
  public static let destructive = FKLocalNotificationActionOptions(rawValue: 1 << 1)

  /// Bring the app to the foreground when the action is selected.
  public static let foreground = FKLocalNotificationActionOptions(rawValue: 1 << 2)
}

/// Action button attached to a notification category.
public struct FKLocalNotificationAction: Sendable, Hashable {
  /// Unique action identifier.
  public var identifier: String

  /// Button title shown to the user.
  public var title: String

  /// Action behavior options.
  public var options: FKLocalNotificationActionOptions

  /// Creates a notification action.
  public init(
    identifier: String,
    title: String,
    options: FKLocalNotificationActionOptions = []
  ) {
    self.identifier = identifier
    self.title = title
    self.options = options
  }
}

/// Notification category grouping custom action buttons.
public struct FKLocalNotificationCategory: Sendable, Hashable {
  /// Unique category identifier referenced by ``FKLocalNotificationRequest/categoryIdentifier``.
  public var identifier: String

  /// Custom action buttons for this category.
  public var actions: [FKLocalNotificationAction]

  /// Intent identifiers for Siri integration.
  public var intentIdentifiers: [String]

  /// Category display and behavior options.
  public var options: FKLocalNotificationCategoryOptions

  /// Creates a notification category.
  public init(
    identifier: String,
    actions: [FKLocalNotificationAction] = [],
    intentIdentifiers: [String] = [],
    options: FKLocalNotificationCategoryOptions = []
  ) {
    self.identifier = identifier
    self.actions = actions
    self.intentIdentifiers = intentIdentifiers
    self.options = options
  }
}
