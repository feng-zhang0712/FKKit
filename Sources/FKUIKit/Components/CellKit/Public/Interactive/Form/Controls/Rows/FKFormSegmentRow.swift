import Foundation

/// ListKit-friendly row model for ``FKFormCellSegmentCell`` (F-07).
public struct FKFormSegmentRow: Sendable, Equatable, Hashable {
  public var id: String
  public var selectedIndex: Int
  public var configuration: FKFormCellSegmentConfiguration

  /// Creates a segment row model.
  public init(
    id: String,
    selectedIndex: Int = 0,
    configuration: FKFormCellSegmentConfiguration
  ) {
    self.id = id
    self.selectedIndex = selectedIndex
    self.configuration = configuration
  }

  /// Convenience builder for F-07.
  public init(
    id: String,
    selectedIndex: Int = 0,
    label: String? = nil,
    segmentTitles: [String]
  ) {
    self.id = id
    self.selectedIndex = selectedIndex
    self.configuration = .segment(label: label, segmentTitles: segmentTitles, selectedIndex: selectedIndex)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
