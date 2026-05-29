import UIKit

/// Optional caption formatting shown beside or below the icon row.
public struct FKRatingLabelConfiguration: @unchecked Sendable {
  /// When non-empty, used instead of the numeric value text.
  public var customText: String?
  /// Prefix prepended to the formatted value (ignored when ``customText`` is set).
  public var valuePrefix: String
  /// Suffix appended to the formatted value (ignored when ``customText`` is set).
  public var valueSuffix: String

  public init(
    customText: String? = nil,
    valuePrefix: String = "",
    valueSuffix: String = ""
  ) {
    self.customText = customText
    self.valuePrefix = valuePrefix
    self.valueSuffix = valueSuffix
  }
}
