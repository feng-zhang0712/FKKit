import Foundation

/// Configuration for ``FKFormCellPINIndicatorCell`` (X-61).
public struct FKFormCellPINIndicatorConfiguration: Sendable, Equatable {
  public var label: String?
  public var slotCount: Int
  public var filledCount: Int
  public var isEnabled: Bool

  /// Creates a PIN dot indicator configuration.
  public init(
    label: String? = nil,
    slotCount: Int = 6,
    filledCount: Int = 0,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.slotCount = min(max(slotCount, 4), 6)
    self.filledCount = max(0, min(filledCount, self.slotCount))
    self.isEnabled = isEnabled
  }
}
