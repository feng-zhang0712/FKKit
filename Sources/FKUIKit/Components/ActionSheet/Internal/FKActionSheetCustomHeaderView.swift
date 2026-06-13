import UIKit

/// Hosts integrator-built header content above the action table.
@MainActor
final class FKActionSheetCustomHeaderView: UIView {
  private var embeddedView: UIView?
  private var embeddedConstraints: [NSLayoutConstraint] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    insetsLayoutMarginsFromSafeArea = false
    preservesSuperviewLayoutMargins = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    header: FKActionSheetCustomHeader,
    context: FKActionSheetHeaderBuildContext
  ) {
    isAccessibilityElement = true
    accessibilityTraits = .header
    accessibilityLabel = header.accessibilityLabel
    directionalLayoutMargins = header.contentInsets

    if let embeddedView, let update = header.provider.update {
      update(context, embeddedView)
    } else {
      embeddedView?.removeFromSuperview()
      NSLayoutConstraint.deactivate(embeddedConstraints)
      embeddedConstraints = []

      let built = header.provider.build(context)
      embeddedView = built
      built.translatesAutoresizingMaskIntoConstraints = false
      addSubview(built)
      embeddedConstraints = [
        built.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
        built.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
        built.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        built.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
      ]
      NSLayoutConstraint.activate(embeddedConstraints)
    }
  }
}
