import UIKit

enum FKChipRemoveIcon {
  @MainActor
  static func image(pointSize: CGFloat, fallbackSymbolName: String) -> UIImage? {
    let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
    if let bundled = FKUIKitResourceBundle.symbol(named: .close, configuration: configuration) {
      return bundled.withRenderingMode(.alwaysTemplate)
    }
    return UIImage(systemName: fallbackSymbolName, withConfiguration: configuration)?
      .withRenderingMode(.alwaysTemplate)
  }
}
