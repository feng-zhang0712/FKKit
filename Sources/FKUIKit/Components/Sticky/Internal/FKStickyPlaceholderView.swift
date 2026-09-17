import UIKit

/// Same-size spacer inserted while a sticky target is reparented into the overlay.
@MainActor
final class FKStickyPlaceholderView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear
    isAccessibilityElement = false
    accessibilityIdentifier = "fk.sticky.placeholder"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
