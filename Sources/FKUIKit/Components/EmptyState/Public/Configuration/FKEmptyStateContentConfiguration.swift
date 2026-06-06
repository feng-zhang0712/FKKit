import UIKit

/// Built-in illustration metadata for ``FKEmptyStateView``.
public struct FKEmptyStateImageContent {
  /// Illustration asset.
  public var image: UIImage
  /// Applied to the built-in `UIImageView` (`scaleAspectFit` by default).
  public var contentMode: UIView.ContentMode
  /// When set, the illustration is rendered as a template image with this tint (useful for SF Symbols).
  public var tintColor: UIColor?
  /// VoiceOver label for the illustration; when `nil` the image is not an accessibility element.
  public var accessibilityLabel: String?

  public init(
    image: UIImage,
    contentMode: UIView.ContentMode = .scaleAspectFit,
    tintColor: UIColor? = nil,
    accessibilityLabel: String? = nil
  ) {
    self.image = image
    self.contentMode = contentMode
    self.tintColor = tintColor
    self.accessibilityLabel = accessibilityLabel
  }

  /// Creates image content from an SF Symbol at a scenario-friendly size.
  public static func systemSymbol(
    _ systemName: String,
    pointSize: CGFloat = 44,
    weight: UIImage.SymbolWeight = .medium
  ) -> FKEmptyStateImageContent {
    let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    let image = UIImage(systemName: systemName, withConfiguration: configuration) ?? UIImage()
    return FKEmptyStateImageContent(image: image)
  }
}

/// Custom view placement for advanced illustration composition.
public struct FKEmptyStateCustomAccessory {
  /// Custom view (e.g. Lottie); `nil` reserves placement until a view is provided.
  public var view: UIView?
  /// Placement relative to the built-in image and text stack.
  public var placement: FKEmptyStateCustomPlacement

  public init(view: UIView? = nil, placement: FKEmptyStateCustomPlacement = .belowImage) {
    self.view = view
    self.placement = placement
  }
}

/// Copy, illustration, and loading subtitle for ``FKEmptyStateView``.
///
/// Use `nil` title/description/image to omit a block entirely.
public struct FKEmptyStateContentConfiguration {
  /// Main illustration; omitted when `nil`.
  public var image: FKEmptyStateImageContent?
  /// Primary headline for empty/error; also fallback text for loading if ``loadingMessage`` is `nil`.
  public var title: String?
  /// Secondary body copy (empty/error; optional during loading via ``FKEmptyStateLoadingBehavior/hidesDescription``).
  public var description: String?
  /// Preferred loading subtitle; when `nil` and `phase == .loading`, ``title`` is shown under the spinner.
  public var loadingMessage: String?
  /// Optional custom illustration view and placement.
  public var customAccessory: FKEmptyStateCustomAccessory?

  public init(
    image: FKEmptyStateImageContent? = nil,
    title: String? = nil,
    description: String? = nil,
    loadingMessage: String? = nil,
    customAccessory: FKEmptyStateCustomAccessory? = nil
  ) {
    self.image = image
    self.title = title
    self.description = description
    self.loadingMessage = loadingMessage
    self.customAccessory = customAccessory
  }
}

public extension FKEmptyStateContentConfiguration {
  /// Replaces ``image`` with a plain `UIImage` using default content mode.
  mutating func setImage(_ image: UIImage?) {
    self.image = image.map { FKEmptyStateImageContent(image: $0) }
  }

  /// Replaces ``image`` with an SF Symbol at scenario-friendly sizing.
  mutating func setSystemSymbol(_ systemName: String) {
    image = .systemSymbol(systemName)
  }
}
