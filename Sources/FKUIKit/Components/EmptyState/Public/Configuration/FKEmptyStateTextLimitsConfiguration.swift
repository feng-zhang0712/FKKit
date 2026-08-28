import Foundation

/// Line and character limits for title, description, and loading copy in ``FKEmptyStateView``.
///
/// Limits are applied at display time so hosts can pass raw API error strings without breaking layout.
/// Set individual properties to `nil` to disable that limit.
public struct FKEmptyStateTextLimitsConfiguration: Equatable, Sendable {
  /// Maximum lines for the title label. `nil` means unlimited (`numberOfLines = 0`).
  public var maxTitleLines: Int?
  /// Maximum lines for the description label. `nil` means unlimited.
  public var maxDescriptionLines: Int?
  /// Maximum lines for the loading subtitle. When `nil`, ``maxTitleLines`` is used.
  public var maxLoadingMessageLines: Int?

  /// Maximum characters shown for the title before line clamping. `nil` means unlimited.
  public var maxTitleCharacters: Int?
  /// Maximum characters shown for the description. `nil` means unlimited.
  public var maxDescriptionCharacters: Int?
  /// Maximum characters for the loading subtitle. When `nil`, ``maxTitleCharacters`` is used.
  public var maxLoadingMessageCharacters: Int?

  /// Appended when character truncation removes trailing content.
  public var truncationSuffix: String

  /// When `true`, VoiceOver reads the full untruncated string even when display text is clipped.
  public var preservesFullTextForAccessibility: Bool

  public init(
    maxTitleLines: Int? = 2,
    maxDescriptionLines: Int? = 4,
    maxLoadingMessageLines: Int? = nil,
    maxTitleCharacters: Int? = nil,
    maxDescriptionCharacters: Int? = 200,
    maxLoadingMessageCharacters: Int? = nil,
    truncationSuffix: String = "…",
    preservesFullTextForAccessibility: Bool = true
  ) {
    self.maxTitleLines = maxTitleLines
    self.maxDescriptionLines = maxDescriptionLines
    self.maxLoadingMessageLines = maxLoadingMessageLines
    self.maxTitleCharacters = maxTitleCharacters
    self.maxDescriptionCharacters = maxDescriptionCharacters
    self.maxLoadingMessageCharacters = maxLoadingMessageCharacters
    self.truncationSuffix = truncationSuffix
    self.preservesFullTextForAccessibility = preservesFullTextForAccessibility
  }

  /// Disables all line and character limits (unlimited display).
  public static let unlimited = FKEmptyStateTextLimitsConfiguration(
    maxTitleLines: nil,
    maxDescriptionLines: nil,
    maxLoadingMessageLines: nil,
    maxTitleCharacters: nil,
    maxDescriptionCharacters: nil,
    maxLoadingMessageCharacters: nil
  )
}
