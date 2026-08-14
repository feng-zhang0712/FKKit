import UIKit

/// Stable identifier for a radio option inside ``FKRadioGroup``.
public typealias FKRadioOptionID = String

/// A single mutually exclusive option in ``FKRadioGroup``.
public struct FKRadioOption: Hashable, @unchecked Sendable, Identifiable {
  public var id: FKRadioOptionID
  public var title: String
  public var subtitle: String?
  public var image: UIImage?
  public var isEnabled: Bool
  public var accessibilityLabel: String?

  public init(
    id: FKRadioOptionID,
    title: String,
    subtitle: String? = nil,
    image: UIImage? = nil,
    isEnabled: Bool = true,
    accessibilityLabel: String? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.image = image
    self.isEnabled = isEnabled
    self.accessibilityLabel = accessibilityLabel
  }

  public static func == (lhs: FKRadioOption, rhs: FKRadioOption) -> Bool {
    lhs.id == rhs.id
      && lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle
      && lhs.isEnabled == rhs.isEnabled
      && lhs.accessibilityLabel == rhs.accessibilityLabel
      && lhs.image === rhs.image
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(subtitle)
    hasher.combine(isEnabled)
    hasher.combine(accessibilityLabel)
  }
}
