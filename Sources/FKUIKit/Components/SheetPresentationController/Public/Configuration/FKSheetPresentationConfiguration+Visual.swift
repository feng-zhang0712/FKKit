import UIKit

public extension FKSheetPresentationConfiguration {
  /// Haptics behavior around lifecycle transitions.
  struct HapticsConfiguration: Sendable, Equatable {
    /// Whether haptics are generated.
    public var isEnabled: Bool
    /// Feedback style for completion events.
    public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle

    /// Creates a haptics configuration.
    public init(isEnabled: Bool = false, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
      self.isEnabled = isEnabled
      self.feedbackStyle = feedbackStyle
    }
  }

  /// Accessibility behavior for announcements and focus.
  struct AccessibilityConfiguration: Sendable, Equatable {
    /// Posts screen changed notifications after presentation.
    public var announcesScreenChange: Bool
    /// Optional label announced when content appears.
    public var announcement: String?
    /// Backdrop accessibility label.
    public var dismissLabel: String
    /// Backdrop accessibility action title.
    public var dismissActionName: String
    /// Grabber accessibility label.
    public var grabberLabel: String
    /// Grabber accessibility hint.
    public var grabberHint: String

    /// Creates accessibility behavior.
    public init(
      announcesScreenChange: Bool = true,
      announcement: String? = nil,
      dismissLabel: String = FKUIKitI18n.string("fkuikit.sheet.dismiss_label"),
      dismissActionName: String = FKUIKitI18n.string("fkuikit.sheet.dismiss_action"),
      grabberLabel: String = FKUIKitI18n.string("fkuikit.sheet.grabber_label"),
      grabberHint: String = FKUIKitI18n.string("fkuikit.sheet.grabber_hint")
    ) {
      self.announcesScreenChange = announcesScreenChange
      self.announcement = announcement
      self.dismissLabel = dismissLabel
      self.dismissActionName = dismissActionName
      self.grabberLabel = grabberLabel
      self.grabberHint = grabberHint
    }
  }
}
