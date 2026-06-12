import Foundation

/// Configuration for ``FKFormCellNPSScaleCell`` (X-65).
public struct FKFormCellNPSScaleConfiguration: Sendable, Equatable {
  public var label: String?
  public var minimumScore: Int
  public var maximumScore: Int
  public var selectedScore: Int?
  public var isEnabled: Bool

  /// Creates an NPS scale configuration.
  public init(
    label: String? = "How likely are you to recommend us?",
    minimumScore: Int = 0,
    maximumScore: Int = 10,
    selectedScore: Int? = nil,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.minimumScore = minimumScore
    self.maximumScore = maximumScore
    self.selectedScore = selectedScore
    self.isEnabled = isEnabled
  }
}
