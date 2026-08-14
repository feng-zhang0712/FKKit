import UIKit

/// Title, subtitle, and optional leading image for ``FKRadioButton``.
public struct FKRadioButtonContentConfiguration: @unchecked Sendable, Equatable {
  public var title: String?
  public var attributedTitle: AttributedString?
  public var subtitle: String?
  /// Drawn between indicator and title when ``FKSelectionControlIndicatorEdge/leading``.
  public var image: UIImage?
  /// When `nil`, defaults to 24×24.
  public var imageSize: CGSize?

  public init(
    title: String? = nil,
    attributedTitle: AttributedString? = nil,
    subtitle: String? = nil,
    image: UIImage? = nil,
    imageSize: CGSize? = nil
  ) {
    self.title = title
    self.attributedTitle = attributedTitle
    self.subtitle = subtitle
    self.image = image
    self.imageSize = imageSize
  }

  public static func == (lhs: FKRadioButtonContentConfiguration, rhs: FKRadioButtonContentConfiguration) -> Bool {
    lhs.title == rhs.title
      && lhs.attributedTitle == rhs.attributedTitle
      && lhs.subtitle == rhs.subtitle
      && lhs.image === rhs.image
      && lhs.imageSize == rhs.imageSize
  }
}
