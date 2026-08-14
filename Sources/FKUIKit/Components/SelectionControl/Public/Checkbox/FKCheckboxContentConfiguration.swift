import UIKit

/// Title, subtitle, and required marker for ``FKCheckbox``.
public struct FKCheckboxContentConfiguration: @unchecked Sendable, Equatable {
  /// Plain title; ignored when ``attributedTitle`` is set.
  public var title: String?
  /// Preferred over ``title`` when set. Links invoke ``FKCheckbox/onLinkActivated``.
  public var attributedTitle: AttributedString?
  /// Secondary line under the title.
  public var subtitle: String?
  /// Appends a trailing red asterisk and VoiceOver “required”.
  public var isRequired: Bool

  public init(
    title: String? = nil,
    attributedTitle: AttributedString? = nil,
    subtitle: String? = nil,
    isRequired: Bool = false
  ) {
    self.title = title
    self.attributedTitle = attributedTitle
    self.subtitle = subtitle
    self.isRequired = isRequired
  }
}
