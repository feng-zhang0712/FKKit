import UIKit

/// Hosts a single trailing accessory for `UITextField.rightView` using intrinsic content size.
///
/// `UITextField` probes `rightView` with temporary zero-size constraints during editing transitions.
/// Accessory controls must not be assigned as `rightView` directly when they carry required
/// width/height constraints — this host reports a stable `intrinsicContentSize` instead.
final class FKTextFieldRightAccessoryHostView: UIView {
  private let contentView: UIView
  private var contentSize: CGSize
  private let horizontalPadding: CGFloat

  init(contentView: UIView, contentSize: CGSize, horizontalPadding: CGFloat) {
    self.contentView = contentView
    self.contentSize = contentSize
    self.horizontalPadding = horizontalPadding
    super.init(frame: .zero)
    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
      contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: contentSize.width + horizontalPadding * 2, height: contentSize.height)
  }

  /// Refreshes the host size when hosted content changes (e.g. counter text width).
  func updateContentSize(_ size: CGSize) {
    guard contentSize != size else { return }
    contentSize = size
    invalidateIntrinsicContentSize()
  }
}
