import UIKit

public extension FKButton {
  /// Configures badge placement for a typical button corner badge and returns ``UIView/fk_badge`` for further updates.
  @MainActor
  @discardableResult
  func configureBadge(
    anchor: FKBadgeAnchor = .topTrailing,
    offset: UIOffset = .zero,
    configuration: FKBadgeConfiguration? = nil
  ) -> FKBadgeController {
    let controller = fk_badge
    controller.anchor = anchor
    controller.offset = offset
    if let configuration {
      controller.configuration = configuration
    }
    return controller
  }
}
