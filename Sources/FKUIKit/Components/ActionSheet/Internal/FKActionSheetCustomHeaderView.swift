import UIKit

@MainActor
final class FKActionSheetCustomHeaderView: UIView {
  private let hostView = UIView()
  private var embeddedView: UIView?

  override init(frame: CGRect) {
    super.init(frame: frame)
    hostView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostView)
    NSLayoutConstraint.activate([
      hostView.topAnchor.constraint(equalTo: topAnchor),
      hostView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
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

    let insets = header.contentInsets
    hostView.layoutMargins = UIEdgeInsets(
      top: insets.top,
      left: insets.leading,
      bottom: insets.bottom,
      right: insets.trailing
    )

    if let embeddedView, let update = header.provider.update {
      update(context, embeddedView)
    } else {
      embeddedView?.removeFromSuperview()
      let built = header.provider.build(context)
      embeddedView = built
      built.translatesAutoresizingMaskIntoConstraints = false
      hostView.addSubview(built)
      NSLayoutConstraint.activate([
        built.topAnchor.constraint(equalTo: hostView.layoutMarginsGuide.topAnchor),
        built.leadingAnchor.constraint(equalTo: hostView.layoutMarginsGuide.leadingAnchor),
        built.trailingAnchor.constraint(equalTo: hostView.layoutMarginsGuide.trailingAnchor),
        built.bottomAnchor.constraint(equalTo: hostView.layoutMarginsGuide.bottomAnchor),
      ])
    }
  }
}
