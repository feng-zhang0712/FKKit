import Foundation

// MARK: - Error presentation

/// User-visible error state paired with ``FKListPresentationState/error(_:)``.
public struct FKListErrorPresentation: Equatable, Sendable {
  public var title: String
  public var message: String?
  public var debugDescription: String?

  public init(title: String, message: String? = nil, debugDescription: String? = nil) {
    self.title = title
    self.message = message
    self.debugDescription = debugDescription
  }
}

// MARK: - Presentation state

/// High-level list UI state driving skeleton, empty, refresh, and content visibility.
public enum FKListPresentationState: Equatable, Sendable {
  case initialLoading
  case content
  case empty
  case error(FKListErrorPresentation)
  case refreshing
  case loadingNextPage
}

// MARK: - Empty policy

/// Controls where empty and error overlays are anchored.
public enum FKListEmptyPresentationPolicy: Sendable, Equatable {
  /// Applies ``FKEmptyState`` on the scroll view — recommended default.
  case overlayScrollView
  /// Hides the list and shows empty state on the view controller root view.
  case replaceContent
  /// Keeps the list with zero sections and centers empty content in the background.
  case inlineZeroRows
}

// MARK: - Skeleton policy

/// Initial loading skeleton strategy.
public enum FKListSkeletonPolicy: Sendable, Equatable {
  /// Overlays skeleton on currently visible cells.
  case visibleCells
  /// Full-table overlay via ``FKSkeleton``.
  case fullOverlay
  /// Placeholder skeleton rows (reserved). Currently uses the same full-list overlay as ``fullOverlay``.
  case presetRows(count: Int)
}
