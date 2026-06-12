import Foundation

/// Configuration for ``FKFormCellSegmentCell`` (X-38, F-07).
public struct FKFormCellSegmentConfiguration: Sendable, Equatable {
  public var label: String?
  public var segmentTitles: [String]
  public var selectedIndex: Int
  public var isEnabled: Bool

  /// Creates a segmented control row configuration.
  public init(
    label: String? = nil,
    segmentTitles: [String],
    selectedIndex: Int = 0,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.segmentTitles = segmentTitles
    self.selectedIndex = selectedIndex
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-07)

public extension FKFormCellSegmentConfiguration {
  /// Segmented control preset (F-07).
  static func segment(
    label: String? = nil,
    segmentTitles: [String],
    selectedIndex: Int = 0
  ) -> FKFormCellSegmentConfiguration {
    FKFormCellSegmentConfiguration(
      label: label,
      segmentTitles: segmentTitles,
      selectedIndex: selectedIndex
    )
  }
}
