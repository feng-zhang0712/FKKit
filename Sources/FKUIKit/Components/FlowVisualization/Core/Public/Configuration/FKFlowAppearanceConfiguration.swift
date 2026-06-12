import UIKit

/// Shared appearance tokens for nodes, connectors, and typography.
public struct FKFlowAppearanceConfiguration: @unchecked Sendable, Equatable {
  /// Node geometry preset.
  public var nodeSize: FKFlowNodeSize
  /// Node shape preset.
  public var nodeShape: FKFlowNodeShape
  /// Spacing density.
  public var density: FKFlowDensity
  /// Connector stroke between nodes.
  public var connector: FKFlowConnectorStyle
  /// Per-state node styling.
  public var nodeAppearances: [FKFlowStepState: FKFlowNodeAppearance]
  /// Title text style.
  public var titleFont: UIFont
  /// Subtitle text style.
  public var subtitleFont: UIFont
  /// Caption text style (timeline).
  public var captionFont: UIFont
  /// Timestamp text style (timeline).
  public var timestampFont: UIFont
  /// Title color.
  public var titleColor: UIColor
  /// Subtitle color.
  public var subtitleColor: UIColor
  /// Caption color.
  public var captionColor: UIColor
  /// Timestamp color.
  public var timestampColor: UIColor
  /// Emphasizes the current step title with semibold weight when `true`.
  public var emphasizesCurrentTitle: Bool
  /// Applies strikethrough to skipped step titles.
  public var strikethroughSkippedTitles: Bool
  /// Treats `.skipped` as completed for connector fill.
  public var treatsSkippedAsCompletedForConnectors: Bool
  /// Scales node diameter slightly at larger content sizes.
  public var scalesNodeWithContentSize: Bool
  /// Optional edge fade when horizontally scrollable.
  public var showsScrollEdgeFade: Bool

  public init(
    nodeSize: FKFlowNodeSize = .medium,
    nodeShape: FKFlowNodeShape = .circle,
    density: FKFlowDensity = .regular,
    connector: FKFlowConnectorStyle = .init(),
    nodeAppearances: [FKFlowStepState: FKFlowNodeAppearance] = FKFlowAppearanceConfiguration.defaultNodeAppearances,
    titleFont: UIFont = .preferredFont(forTextStyle: .footnote),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .caption2),
    captionFont: UIFont = .preferredFont(forTextStyle: .caption1),
    timestampFont: UIFont = .preferredFont(forTextStyle: .caption2),
    titleColor: UIColor = .label,
    subtitleColor: UIColor = .secondaryLabel,
    captionColor: UIColor = .secondaryLabel,
    timestampColor: UIColor = .tertiaryLabel,
    emphasizesCurrentTitle: Bool = true,
    strikethroughSkippedTitles: Bool = true,
    treatsSkippedAsCompletedForConnectors: Bool = true,
    scalesNodeWithContentSize: Bool = true,
    showsScrollEdgeFade: Bool = false
  ) {
    self.nodeSize = nodeSize
    self.nodeShape = nodeShape
    self.density = density
    self.connector = connector
    self.nodeAppearances = nodeAppearances
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.captionFont = captionFont
    self.timestampFont = timestampFont
    self.titleColor = titleColor
    self.subtitleColor = subtitleColor
    self.captionColor = captionColor
    self.timestampColor = timestampColor
    self.emphasizesCurrentTitle = emphasizesCurrentTitle
    self.strikethroughSkippedTitles = strikethroughSkippedTitles
    self.treatsSkippedAsCompletedForConnectors = treatsSkippedAsCompletedForConnectors
    self.scalesNodeWithContentSize = scalesNodeWithContentSize
    self.showsScrollEdgeFade = showsScrollEdgeFade
  }

  /// Default dynamic-color node styling per state.
  public static var defaultNodeAppearances: [FKFlowStepState: FKFlowNodeAppearance] {
    [
      .completed: FKFlowNodeAppearance(
        fillColor: .systemBlue,
        border: .none,
        iconTint: .white
      ),
      .current: FKFlowNodeAppearance(
        fillColor: .systemBackground,
        border: .custom(color: .systemBlue, width: 2),
        iconTint: .systemBlue
      ),
      .upcoming: FKFlowNodeAppearance(
        fillColor: .systemBackground,
        border: .custom(color: .tertiaryLabel, width: 1.5),
        iconTint: .tertiaryLabel
      ),
      .error: FKFlowNodeAppearance(
        fillColor: .systemRed,
        border: .none,
        iconTint: .white
      ),
      .skipped: FKFlowNodeAppearance(
        fillColor: .secondarySystemBackground,
        border: .custom(color: .tertiaryLabel, width: 1),
        iconTint: .tertiaryLabel
      ),
      .disabled: FKFlowNodeAppearance(
        fillColor: .secondarySystemBackground,
        border: .custom(color: .quaternaryLabel, width: 1),
        iconTint: .quaternaryLabel
      ),
    ]
  }

  /// Resolved appearance for a state, falling back to `.upcoming`.
  public func appearance(for state: FKFlowStepState) -> FKFlowNodeAppearance {
    nodeAppearances[state] ?? nodeAppearances[.upcoming] ?? .init()
  }
}
