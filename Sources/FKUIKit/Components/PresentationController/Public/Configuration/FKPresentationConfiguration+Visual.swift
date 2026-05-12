import UIKit

public extension FKPresentationConfiguration {
  /// Haptics behavior around lifecycle transitions.
  struct HapticsConfiguration {
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
  struct AccessibilityConfiguration {
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
      dismissLabel: String = "Dismiss",
      dismissActionName: String = "Dismiss",
      grabberLabel: String = "Handle",
      grabberHint: String = "Swipe up or down to adjust."
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
