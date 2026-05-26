import UIKit

/// Builds and optionally updates custom header content.
public final class FKActionSheetCustomHeaderProvider: @unchecked Sendable {
  /// Creates a new header view.
  public var build: @MainActor (FKActionSheetHeaderBuildContext) -> UIView
  /// Optional in-place update when the same view instance is reused.
  public var update: (@MainActor (FKActionSheetHeaderBuildContext, UIView) -> Void)?

  /// Creates a header provider.
  public init(
    build: @escaping @MainActor (FKActionSheetHeaderBuildContext) -> UIView,
    update: (@MainActor (FKActionSheetHeaderBuildContext, UIView) -> Void)? = nil
  ) {
    self.build = build
    self.update = update
  }
}

/// Configuration for a custom header section.
public struct FKActionSheetCustomHeader: Identifiable, Equatable {
  /// Stable identifier.
  public let id: UUID
  /// Optional fixed total header height (including ``contentInsets``); `nil` uses Auto Layout fitting size.
  public var preferredHeight: CGFloat?
  /// Horizontal insets around the custom view.
  public var contentInsets: NSDirectionalEdgeInsets
  /// VoiceOver label for the header container.
  public var accessibilityLabel: String?
  /// View builder.
  public var provider: FKActionSheetCustomHeaderProvider

  /// Creates a custom header configuration.
  public init(
    id: UUID = UUID(),
    preferredHeight: CGFloat? = nil,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 12, leading: 16, bottom: 4, trailing: 16),
    accessibilityLabel: String? = nil,
    provider: FKActionSheetCustomHeaderProvider
  ) {
    self.id = id
    self.preferredHeight = preferredHeight.map { max(0, $0) }
    self.contentInsets = contentInsets
    self.accessibilityLabel = accessibilityLabel
    self.provider = provider
  }

  public static func == (lhs: FKActionSheetCustomHeader, rhs: FKActionSheetCustomHeader) -> Bool {
    lhs.id == rhs.id
      && lhs.preferredHeight == rhs.preferredHeight
      && lhs.contentInsets == rhs.contentInsets
      && lhs.accessibilityLabel == rhs.accessibilityLabel
  }
}

/// Builds and optionally updates custom row content.
public final class FKActionSheetCustomRowProvider: @unchecked Sendable {
  /// Creates a new row content view.
  public var build: @MainActor (FKActionSheetRowBuildContext) -> UIView
  /// Optional in-place update when the same view instance is reused.
  public var update: (@MainActor (FKActionSheetRowBuildContext, UIView) -> Void)?

  /// Creates a row provider.
  public init(
    build: @escaping @MainActor (FKActionSheetRowBuildContext) -> UIView,
    update: (@MainActor (FKActionSheetRowBuildContext, UIView) -> Void)? = nil
  ) {
    self.build = build
    self.update = update
  }
}

/// Configuration for a custom action row.
public struct FKActionSheetCustomRow: Identifiable, Equatable {
  /// Stable identifier (should match ``FKActionSheetAction/id`` when paired).
  public var id: UUID
  /// Reuse identifier for UITableView cell pooling.
  public var reuseIdentifier: String
  /// Optional fixed row height; `nil` uses Auto Layout fitting size with a minimum from appearance.
  public var preferredHeight: CGFloat?
  /// When `false`, taps do not invoke selection semantics.
  public var isSelectable: Bool
  /// View builder.
  public var provider: FKActionSheetCustomRowProvider

  /// Creates a custom row configuration.
  public init(
    id: UUID = UUID(),
    reuseIdentifier: String = "FKActionSheetCustomRow",
    preferredHeight: CGFloat? = nil,
    isSelectable: Bool = true,
    provider: FKActionSheetCustomRowProvider
  ) {
    self.id = id
    self.reuseIdentifier = reuseIdentifier
    self.preferredHeight = preferredHeight.map { max(0, $0) }
    self.isSelectable = isSelectable
    self.provider = provider
  }

  public static func == (lhs: FKActionSheetCustomRow, rhs: FKActionSheetCustomRow) -> Bool {
    lhs.id == rhs.id
      && lhs.reuseIdentifier == rhs.reuseIdentifier
      && lhs.preferredHeight == rhs.preferredHeight
      && lhs.isSelectable == rhs.isSelectable
  }
}

/// Row rendering mode for ``FKActionSheetAction``.
public enum FKActionSheetRowContent: Equatable {
  /// Built-in title/subtitle/icon layout.
  case standard
  /// Built-in title row with a trailing switch (does not dismiss on toggle).
  case toggle(FKActionSheetToggleRow)
  /// Host-provided view from ``FKActionSheetCustomRow``.
  case custom(FKActionSheetCustomRow)
}

/// Header content for ``FKActionSheetConfiguration``.
public enum FKActionSheetHeaderContent: Equatable {
  /// Built-in title and message header.
  case text(FKActionSheetHeader)
  /// Host-provided header view.
  case custom(FKActionSheetCustomHeader)

  /// Whether the header contributes visible content.
  public var isEmpty: Bool {
    switch self {
    case .text(let header):
      return header.isEmpty
    case .custom:
      return false
    }
  }
}
