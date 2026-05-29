import FKUIKit
import UIKit

/// Centered ``FKSheetPresentationController`` helpers for rating demos.
@MainActor
enum FKRatingSheetExampleSupport {

  static func centerCardConfiguration(
    dismissOnBackdrop: Bool = true,
    width: CGFloat = 340
  ) -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration.centerCard
    configuration.layout = .center(
      .init(
        size: .fitted(maxSize: .init(width: width, height: 520)),
        minimumMargins: .init(top: 28, leading: 28, bottom: 28, trailing: 28),
        dismissEnabled: false
      )
    )
    configuration.cornerRadius = 16
    configuration.backdropStyle = .dim(alpha: 0.42)
    configuration.safeAreaPolicy = .containerRespectsSafeArea
    configuration.dismissBehavior.allowsTapOutside = dismissOnBackdrop
    configuration.dismissBehavior.allowsBackdropTap = dismissOnBackdrop
    return configuration
  }

  static func centerAlertConfiguration(
    size: CGSize = .init(width: 320, height: 400)
  ) -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration.centerAlert
    configuration.layout = .center(
      .init(
        size: .fixed(size),
        minimumMargins: .init(top: 32, leading: 32, bottom: 32, trailing: 32),
        dismissEnabled: true,
        dismissProgressThreshold: 0.28
      )
    )
    configuration.cornerRadius = 14
    configuration.backdropStyle = .dim(alpha: 0.48)
    return configuration
  }

  static func appStoreConfiguration() -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration.centerAlert
    configuration.layout = .center(
      .init(
        size: .fitted(maxSize: .init(width: 320, height: 480)),
        minimumMargins: .init(top: 32, leading: 32, bottom: 32, trailing: 32),
        dismissEnabled: false
      )
    )
    configuration.cornerRadius = 14
    configuration.backdropStyle = .dim(alpha: 0.48)
    configuration.safeAreaPolicy = .containerRespectsSafeArea
    configuration.dismissBehavior.allowsTapOutside = false
    configuration.dismissBehavior.allowsBackdropTap = false
    configuration.animation.preset = .systemLike
    configuration.shadow = .custom(
      color: .black,
      opacity: 0.22,
      radius: 24,
      offset: CGSize(width: 0, height: 12)
    )
    return configuration
  }

  @discardableResult
  static func present(
    content: UIViewController,
    from presenter: UIViewController,
    configuration: FKSheetPresentationConfiguration,
    onDismiss: (() -> Void)? = nil
  ) -> FKSheetPresentationController {
    var handlers = FKSheetPresentationLifecycleHandlers()
    handlers.didDismiss = { onDismiss?() }
    return FKSheetPresentationController.present(
      contentController: content,
      from: presenter,
      configuration: configuration,
      delegate: nil,
      handlers: handlers,
      animated: true,
      completion: nil
    )
  }

  static func makeAppIconView() -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .systemBlue
    container.layer.cornerRadius = 16
    container.layer.cornerCurve = .continuous
    container.clipsToBounds = true

    let glyph = UIImageView(image: UIImage(systemName: "swift"))
    glyph.translatesAutoresizingMaskIntoConstraints = false
    glyph.tintColor = .white
    glyph.contentMode = .scaleAspectFit
    container.addSubview(glyph)

    NSLayoutConstraint.activate([
      container.widthAnchor.constraint(equalToConstant: 72),
      container.heightAnchor.constraint(equalToConstant: 72),
      glyph.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      glyph.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      glyph.widthAnchor.constraint(equalToConstant: 36),
      glyph.heightAnchor.constraint(equalToConstant: 36),
    ])
    return container
  }

  static func makeHorizontalButtonRow(
    leadingTitle: String,
    trailingTitle: String,
    leadingAction: @escaping () -> Void,
    trailingAction: @escaping () -> Void
  ) -> UIStackView {
    let leading = UIButton(type: .system)
    leading.configuration = .gray()
    leading.configuration?.cornerStyle = .large
    leading.setTitle(leadingTitle, for: .normal)
    leading.addAction(UIAction { _ in leadingAction() }, for: .touchUpInside)

    let trailing = UIButton(type: .system)
    trailing.configuration = .filled()
    trailing.configuration?.cornerStyle = .large
    trailing.setTitle(trailingTitle, for: .normal)
    trailing.addAction(UIAction { _ in trailingAction() }, for: .touchUpInside)

    let row = UIStackView(arrangedSubviews: [leading, trailing])
    row.axis = .horizontal
    row.spacing = 12
    row.distribution = .fillEqually
    return row
  }

  static func updatePreferredContentSize(for viewController: UIViewController, width: CGFloat) {
    let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
    let fitted = viewController.view.systemLayoutSizeFitting(
      target,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    let newSize = CGSize(width: width, height: ceil(fitted.height))
    guard viewController.preferredContentSize != newSize else { return }
    viewController.preferredContentSize = newSize
  }
}
