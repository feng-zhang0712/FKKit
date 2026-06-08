import UIKit

/// Renders ``FKImageViewPlaceholder`` inside ``FKImageView`` using a single active content slot.
@MainActor
final class FKImageViewPlaceholderView: UIView {
  private enum ActiveSlot {
    case image(UIImageView)
    case label(UILabel)
    case custom(UIView)
  }

  private var activeSlot: ActiveSlot?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    isHidden = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(placeholder: FKImageViewPlaceholder) {
    clearActiveSlot()
    switch placeholder {
    case .none:
      isHidden = true
      backgroundColor = .clear
    case .image(let image):
      isHidden = false
      backgroundColor = .clear
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      install(imageView, slot: .image(imageView))
    case .color(let color):
      isHidden = false
      backgroundColor = color
    case .symbol(let name, let pointSize, let weight):
      isHidden = false
      backgroundColor = .clear
      let imageView = UIImageView()
      imageView.contentMode = .center
      imageView.tintColor = .secondaryLabel
      let config = UIImage.SymbolConfiguration(pointSize: pointSize ?? 28, weight: weight ?? .regular)
      imageView.image = UIImage(systemName: name, withConfiguration: config)?
        .withRenderingMode(.alwaysTemplate)
      install(imageView, slot: .image(imageView))
    case .initials(let text, let font, let textColor, let backgroundColor):
      isHidden = false
      self.backgroundColor = backgroundColor ?? .secondarySystemFill
      let label = UILabel()
      label.text = text
      label.textAlignment = .center
      label.adjustsFontForContentSizeCategory = true
      label.font = font ?? UIFont.preferredFont(forTextStyle: .title2)
      label.textColor = textColor ?? .label
      install(label, slot: .label(label))
    }
  }

  func setCustomContent(_ view: UIView) {
    clearActiveSlot()
    backgroundColor = .clear
    isHidden = false
    install(view, slot: .custom(view))
  }

  func clearCustomContent() {
    if case .custom = activeSlot {
      clearActiveSlot()
    }
  }

  private func install(_ view: UIView, slot: ActiveSlot) {
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.topAnchor.constraint(equalTo: topAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    activeSlot = slot
  }

  private func clearActiveSlot() {
    switch activeSlot {
    case .image(let imageView):
      imageView.removeFromSuperview()
    case .label(let label):
      label.removeFromSuperview()
    case .custom(let view):
      view.removeFromSuperview()
    case nil:
      break
    }
    activeSlot = nil
    backgroundColor = .clear
  }
}
