import UIKit

/// Visible label text, placement, typography, logical range, and optional ``NumberFormatter``.
///
/// - Note: Marked `@unchecked Sendable` because `UIFont` / `NumberFormatter` are not `Sendable`.
public struct FKProgressBarLabelConfiguration: @unchecked Sendable {
  /// How the visible label chooses its text when ``labelPlacement`` is not ``FKProgressBarLabelPlacement/none``.
  public var labelContentMode: FKProgressBarLabelContentMode
  /// Free-form title for ``FKProgressBarLabelContentMode/customTitleOnly``, ``customTitleWhenIdle``, or the first line of ``customTitleWithProgressSubtitle``.
  public var customTitle: String

  public var labelPlacement: FKProgressBarLabelPlacement
  public var labelFormat: FKProgressBarLabelFormat
  public var labelFractionDigits: Int
  public var labelFont: UIFont
  public var labelColor: UIColor
  public var labelPadding: CGFloat
  /// When `true`, the label ignores `labelColor` and uses `UIColor.label` (adapts in Dark Mode).
  public var labelUsesSemanticLabelColor: Bool

  /// Logical minimum corresponding to progress `0`.
  public var logicalMinimum: Double
  /// Logical maximum corresponding to progress `1`.
  public var logicalMaximum: Double
  /// Optional prefix/suffix around formatted label text (e.g. `" "` + `" MB"`).
  public var labelPrefix: String
  public var labelSuffix: String

  /// Used for `.logicalRangeValue` label format and optional custom grouping.
  public var numberFormatter: NumberFormatter?

  public init(
    labelContentMode: FKProgressBarLabelContentMode = .formattedProgress,
    customTitle: String = "",
    labelPlacement: FKProgressBarLabelPlacement = .none,
    labelFormat: FKProgressBarLabelFormat = .percentInteger,
    labelFractionDigits: Int = 1,
    labelFont: UIFont = .preferredFont(forTextStyle: .footnote),
    labelColor: UIColor = .secondaryLabel,
    labelPadding: CGFloat = 4,
    labelUsesSemanticLabelColor: Bool = false,
    logicalMinimum: Double = 0,
    logicalMaximum: Double = 1,
    labelPrefix: String = "",
    labelSuffix: String = "",
    numberFormatter: NumberFormatter? = nil
  ) {
    self.labelContentMode = labelContentMode
    self.customTitle = customTitle
    self.labelPlacement = labelPlacement
    self.labelFormat = labelFormat
    self.labelFractionDigits = max(0, min(6, labelFractionDigits))
    self.labelFont = labelFont
    self.labelColor = labelColor
    self.labelPadding = max(0, labelPadding)
    self.labelUsesSemanticLabelColor = labelUsesSemanticLabelColor
    self.logicalMinimum = logicalMinimum
    self.logicalMaximum = logicalMaximum
    self.labelPrefix = labelPrefix
    self.labelSuffix = labelSuffix
    self.numberFormatter = numberFormatter
  }
}
