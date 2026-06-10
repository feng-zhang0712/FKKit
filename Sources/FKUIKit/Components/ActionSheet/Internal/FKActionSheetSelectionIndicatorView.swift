import UIKit

/// Selection accessory image for action-sheet rows (FKUIKit bundled symbol images).
@MainActor
final class FKActionSheetSelectionIndicatorView: UIView {
  enum DisplayMode: Equatable {
    case hidden
    case check
    case radio(isSelected: Bool)
  }

  private let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    isHidden = true
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    addSubview(imageView)

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 24),
      imageView.heightAnchor.constraint(equalToConstant: 24),
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: 24, height: 24)
  }

  func apply(mode: DisplayMode, tintColor: UIColor) {
    switch mode {
    case .hidden:
      isHidden = true
      imageView.image = nil
      return
    case .check:
      imageView.image = Self.symbolImage(named: .check)
    case .radio(let isSelected):
      imageView.image = Self.symbolImage(
        named: isSelected ? .radioChecked : .radioUnchecked
      )
    }
    imageView.tintColor = tintColor
    isHidden = imageView.image == nil
  }

  private static func symbolImage(named name: FKUIKitResourceBundle.SymbolName) -> UIImage? {
    FKUIKitResourceBundle.symbol(named: name, configuration: nil)?
      .withRenderingMode(.alwaysTemplate)
  }
}
