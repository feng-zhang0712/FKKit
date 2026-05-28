import UIKit

public extension FKSheetPresentationConfiguration {
  /// Mutates sheet configuration when ``layout`` is `.bottomSheet` or `.topSheet`.
  ///
  /// Returns `false` when the active layout is not a sheet mode (for example `.center` or `.anchor`).
  @discardableResult
  mutating func applyingSheet(_ transform: (inout SheetConfiguration) -> Void) -> Bool {
    switch layout {
    case .bottomSheet(var configuration):
      transform(&configuration)
      layout = .bottomSheet(configuration)
      return true
    case .topSheet(var configuration):
      transform(&configuration)
      layout = .topSheet(configuration)
      return true
    default:
      return false
    }
  }

  /// Mutates center configuration and switches ``layout`` to `.center`.
  @discardableResult
  mutating func applyingCenter(_ transform: (inout CenterConfiguration) -> Void) -> Bool {
    var configuration = center
    transform(&configuration)
    layout = .center(configuration)
    return true
  }

  /// Replaces the active layout with a bottom sheet using the supplied configuration.
  mutating func setBottomSheet(_ sheet: SheetConfiguration) {
    layout = .bottomSheet(sheet)
  }

  /// Replaces the active layout with a top sheet using the supplied configuration.
  mutating func setTopSheet(_ sheet: SheetConfiguration) {
    layout = .topSheet(sheet)
  }

  /// Replaces the active layout with a center modal using the supplied configuration.
  mutating func setCenter(_ center: CenterConfiguration) {
    layout = .center(center)
  }
}
