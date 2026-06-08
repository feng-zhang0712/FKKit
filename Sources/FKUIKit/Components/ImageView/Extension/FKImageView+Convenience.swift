import UIKit

public extension FKImageView {
  /// Sets corner style via fluent configuration mutation.
  func fk_setCornerStyle(_ style: FKImageViewCornerStyle) {
    apply { $0.appearance.cornerStyle = style }
  }

  /// Sets content mode via fluent configuration mutation.
  func fk_setContentMode(_ contentMode: UIView.ContentMode) {
    self.contentMode = contentMode
  }

  /// Sets placeholder via fluent configuration mutation.
  func fk_setPlaceholder(_ placeholder: FKImageViewPlaceholder) {
    apply { $0.loading.placeholder = placeholder }
    updatePlaceholderPresentation()
  }
}

@available(iOS 17.0, *)
public extension FKImageView {
  /// Preferred HDR/SDR rendering forwarded to the inner `UIImageView`.
  var preferredImageDynamicRange: UIImage.DynamicRange {
    get { imageView.preferredImageDynamicRange }
    set { imageView.preferredImageDynamicRange = newValue }
  }
}
