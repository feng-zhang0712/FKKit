import CoreGraphics
import Foundation

/// Direction used by auto-scroll advancement.
public enum FKCarouselScrollDirection: Equatable, Sendable {
  case forward
  case reverse
}

/// Reason reported when the settled page index changes.
public enum FKCarouselPageChangeReason: Equatable, Sendable {
  case userSwipe
  case programmatic
  case autoScroll
  case loopCorrection
  case reload
}

/// High-level carousel interaction phase.
public enum FKCarouselPhase: Equatable, Sendable {
  case idle
  case dragging
  case decelerating
  case programmatic
  case autoAdvancing
}

/// Read-only snapshot of carousel runtime state for debugging and SwiftUI bindings.
public struct FKCarouselStateSnapshot: Equatable, Sendable {
  /// Current interaction phase.
  public var phase: FKCarouselPhase

  /// Logical settled page index (`0 ..< pageCount`).
  public var currentPageIndex: Int

  /// Number of logical pages.
  public var pageCount: Int

  /// Fractional scroll position between pages (`0...1` within the current page span).
  public var scrollProgress: CGFloat

  /// Creates a state snapshot.
  public init(
    phase: FKCarouselPhase = .idle,
    currentPageIndex: Int = 0,
    pageCount: Int = 0,
    scrollProgress: CGFloat = 0
  ) {
    self.phase = phase
    self.currentPageIndex = currentPageIndex
    self.pageCount = pageCount
    self.scrollProgress = scrollProgress
  }
}
