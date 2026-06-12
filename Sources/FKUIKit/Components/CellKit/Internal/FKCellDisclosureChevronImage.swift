import UIKit

/// Resolves the settings-style disclosure chevron for CellKit accessory rows.
@MainActor
enum FKCellDisclosureChevronImage {
  /// Symbol configuration aligned with ``FKCellLayoutMetrics/chevronHeight``.
  private static var symbolConfiguration: UIImage.SymbolConfiguration {
    UIImage.SymbolConfiguration(pointSize: FKCellLayoutMetrics.chevronHeight, weight: .semibold)
  }

  /// Bundled ``chevron_right`` symbol, falling back to the system chevron when unavailable.
  static func make() -> UIImage? {
    if let bundled = FKUIKitResourceBundle.symbol(named: .chevronRight, configuration: symbolConfiguration) {
      return bundled.withRenderingMode(.alwaysTemplate)
    }
    return UIImage(systemName: "chevron.right", withConfiguration: symbolConfiguration)?
      .withRenderingMode(.alwaysTemplate)
  }
}
