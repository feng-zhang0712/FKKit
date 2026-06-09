import Foundation

/// VoiceOver templates and grouping for flow controls.
public struct FKFlowAccessibilityConfiguration: Sendable, Equatable {
  /// Overrides the container accessibility label when non-empty.
  public var customLabel: String?
  /// Default hint for selectable steps when the item has no override.
  public var selectableHint: String?
  /// Format for step indicator rows: `{index}`, `{count}`, `{title}`, `{state}`.
  public var stepLabelFormat: String
  /// Format for timeline rows: `{title}`, `{timestamp}`, `{caption}`, `{state}`.
  public var timelineLabelFormat: String
  /// When `true`, connectors are hidden from VoiceOver.
  public var hidesConnectorsFromAccessibility: Bool

  public init(
    customLabel: String? = nil,
    selectableHint: String? = nil,
    stepLabelFormat: String = "Step {index} of {count}, {title}, {state}",
    timelineLabelFormat: String = "{title}, {timestamp}, {caption}, {state}",
    hidesConnectorsFromAccessibility: Bool = true
  ) {
    self.customLabel = customLabel
    self.selectableHint = selectableHint
    self.stepLabelFormat = stepLabelFormat
    self.timelineLabelFormat = timelineLabelFormat
    self.hidesConnectorsFromAccessibility = hidesConnectorsFromAccessibility
  }
}
