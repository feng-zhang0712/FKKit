import Foundation

/// Line and character limits for toast message, title, and subtitle copy.
///
/// Limits are applied at display time so hosts can pass raw API error strings safely.
/// Set individual properties to `nil` to disable that limit.
public struct FKToastTextLimitsConfiguration: Equatable, Sendable {
  /// Maximum lines for plain `.message` text. `nil` means unlimited.
  public var maxMessageLines: Int?
  /// Maximum lines for `.titleSubtitle` title. `nil` means unlimited.
  public var maxTitleLines: Int?
  /// Maximum lines for `.titleSubtitle` subtitle. `nil` means unlimited.
  public var maxSubtitleLines: Int?

  /// Maximum characters for plain `.message` text before line clamping.
  public var maxMessageCharacters: Int?
  /// Maximum characters for `.titleSubtitle` title.
  public var maxTitleCharacters: Int?
  /// Maximum characters for `.titleSubtitle` subtitle.
  public var maxSubtitleCharacters: Int?

  /// Appended when character truncation removes trailing content.
  public var truncationSuffix: String

  /// When `true`, VoiceOver reads the full untruncated string even when display text is clipped.
  public var preservesFullTextForAccessibility: Bool

  public init(
    maxMessageLines: Int? = 3,
    maxTitleLines: Int? = 2,
    maxSubtitleLines: Int? = 2,
    maxMessageCharacters: Int? = 120,
    maxTitleCharacters: Int? = nil,
    maxSubtitleCharacters: Int? = 120,
    truncationSuffix: String = "…",
    preservesFullTextForAccessibility: Bool = true
  ) {
    self.maxMessageLines = maxMessageLines
    self.maxTitleLines = maxTitleLines
    self.maxSubtitleLines = maxSubtitleLines
    self.maxMessageCharacters = maxMessageCharacters
    self.maxTitleCharacters = maxTitleCharacters
    self.maxSubtitleCharacters = maxSubtitleCharacters
    self.truncationSuffix = truncationSuffix
    self.preservesFullTextForAccessibility = preservesFullTextForAccessibility
  }

  /// Disables all line and character limits (unlimited display).
  public static let unlimited = FKToastTextLimitsConfiguration(
    maxMessageLines: nil,
    maxTitleLines: nil,
    maxSubtitleLines: nil,
    maxMessageCharacters: nil,
    maxTitleCharacters: nil,
    maxSubtitleCharacters: nil
  )

  /// Returns kind-aware defaults used when ``FKToastConfiguration/textLimits`` is untouched.
  public static func defaults(for kind: FKToastKind) -> FKToastTextLimitsConfiguration {
    switch kind {
    case .toast:
      return FKToastTextLimitsConfiguration()
    case .hud:
      return FKToastTextLimitsConfiguration(
        maxMessageLines: 2,
        maxTitleLines: 2,
        maxSubtitleLines: 1,
        maxMessageCharacters: 80,
        maxTitleCharacters: nil,
        maxSubtitleCharacters: 40
      )
    case .snackbar:
      return FKToastTextLimitsConfiguration(
        maxMessageLines: 2,
        maxTitleLines: 2,
        maxSubtitleLines: 2,
        maxMessageCharacters: 100,
        maxTitleCharacters: nil,
        maxSubtitleCharacters: 100
      )
    }
  }
}
