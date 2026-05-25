import UIKit

/// Context passed to custom header builders.
@MainActor
public struct FKActionSheetHeaderBuildContext {
  /// Active appearance.
  public let appearance: FKActionSheetAppearance
  /// Available width for layout.
  public let boundsWidth: CGFloat

  /// Creates a header build context.
  public init(appearance: FKActionSheetAppearance, boundsWidth: CGFloat) {
    self.appearance = appearance
    self.boundsWidth = max(1, boundsWidth)
  }
}

/// Context passed to custom row builders.
@MainActor
public struct FKActionSheetRowBuildContext {
  /// Action descriptor for the row being rendered.
  public let action: FKActionSheetAction
  /// Parent section identifier when applicable.
  public let sectionID: UUID?
  /// Whether the row is rendered in the separated cancel group.
  public let isCancelGroup: Bool
  /// Active appearance.
  public let appearance: FKActionSheetAppearance
  /// Available width for layout.
  public let boundsWidth: CGFloat

  /// Creates a row build context.
  public init(
    action: FKActionSheetAction,
    sectionID: UUID?,
    isCancelGroup: Bool,
    appearance: FKActionSheetAppearance,
    boundsWidth: CGFloat
  ) {
    self.action = action
    self.sectionID = sectionID
    self.isCancelGroup = isCancelGroup
    self.appearance = appearance
    self.boundsWidth = max(1, boundsWidth)
  }
}
