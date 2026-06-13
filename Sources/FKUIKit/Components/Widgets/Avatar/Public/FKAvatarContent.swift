import UIKit

/// Sendable avatar payload for ``FKAvatarGroup`` rows.
public struct FKAvatarContent: Sendable, Equatable, Identifiable {
  /// Stable identity for diffing and accessibility.
  public var id: String
  /// Display name used for initials fallback and VoiceOver.
  public var displayName: String?
  /// Remote image URL.
  public var imageURL: URL?
  /// Local bitmap override.
  public var image: UIImage?

  /// Creates avatar content.
  public init(
    id: String,
    displayName: String? = nil,
    imageURL: URL? = nil,
    image: UIImage? = nil
  ) {
    self.id = id
    self.displayName = displayName
    self.imageURL = imageURL
    self.image = image
  }
}

extension FKAvatarContent {
  public static func == (lhs: FKAvatarContent, rhs: FKAvatarContent) -> Bool {
    lhs.id == rhs.id
      && lhs.displayName == rhs.displayName
      && lhs.imageURL == rhs.imageURL
  }
}
