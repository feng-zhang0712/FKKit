import UIKit

/// Layout and scrolling settings for ``FKStepIndicator``.
public struct FKStepIndicatorLayoutConfiguration: @unchecked Sendable, Equatable {
  /// Horizontal layout variant.
  public var layout: FKStepIndicatorLayout
  /// Content insets around the step row.
  public var contentInsets: UIEdgeInsets
  /// Minimum spacing between nodes.
  public var stepSpacing: CGFloat
  /// Maximum steps visible before enabling horizontal scroll (`0` = no limit).
  public var maxVisibleSteps: Int
  /// Title line limit.
  public var titleNumberOfLines: Int
  /// Subtitle line limit.
  public var subtitleNumberOfLines: Int
  /// When `true`, draws partial fill on the connector after the current step.
  public var showsPartialConnectorFill: Bool

  public init(
    layout: FKStepIndicatorLayout = .horizontalTopLabels,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
    stepSpacing: CGFloat = 8,
    maxVisibleSteps: Int = 0,
    titleNumberOfLines: Int = 2,
    subtitleNumberOfLines: Int = 2,
    showsPartialConnectorFill: Bool = false
  ) {
    self.layout = layout
    self.contentInsets = contentInsets
    self.stepSpacing = max(0, stepSpacing)
    self.maxVisibleSteps = max(0, maxVisibleSteps)
    self.titleNumberOfLines = max(1, titleNumberOfLines)
    self.subtitleNumberOfLines = max(1, subtitleNumberOfLines)
    self.showsPartialConnectorFill = showsPartialConnectorFill
  }
}
