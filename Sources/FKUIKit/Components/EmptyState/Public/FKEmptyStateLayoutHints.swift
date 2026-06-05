import Foundation

// MARK: - Layout context

/// Screen-level context for presets, analytics, and automatic layout tuning (image size, insets, column width).
public enum FKEmptyStateLayoutContext: String, CaseIterable, Equatable, Sendable {
  case list
  case table
  case search
  case detail
  case dialog
  case drawer
  case card
  case fullPage = "full_page"
  case section
}

// MARK: - Density & axis

/// Spacing density hint for app-level presets (explicit model metrics override this).
public enum FKEmptyStateDensity: String, CaseIterable, Equatable, Sendable {
  case compact
  case regular
  case comfortable
}

/// Preferred stack axis; `.horizontal` places the illustration beside the title/description column.
public enum FKEmptyStateAxis: String, CaseIterable, Equatable, Sendable {
  case vertical
  case horizontal
}
