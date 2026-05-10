import UIKit

/// Shared Auto Layout and shadow helpers for ``FKBaseTableViewCell`` and ``FKBaseCollectionViewCell``.
enum FKBaseReusableCellCore {

  static func activateContainerConstraints(
    containerView: UIView,
    contentView: UIView,
    insets: UIEdgeInsets,
    storage: inout [NSLayoutConstraint]
  ) {
    NSLayoutConstraint.deactivate(storage)
    storage = [
      containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
    ]
    NSLayoutConstraint.activate(storage)
  }

  /// Updates `layer.shadowPath` for rounded-rect shadows (reduces off-screen rendering when set).
  static func applyShadowPath(
    to layer: CALayer,
    bounds: CGRect,
    cornerRadius: CGFloat,
    shadowPathInset: CGFloat,
    shadowOpacity: Float,
    shadowRadius: CGFloat
  ) {
    guard shadowOpacity > .zero || shadowRadius > .zero else {
      layer.shadowPath = nil
      return
    }
    let pathRect = bounds.insetBy(dx: shadowPathInset, dy: shadowPathInset)
    layer.shadowPath = UIBezierPath(roundedRect: pathRect, cornerRadius: cornerRadius).cgPath
  }
}
