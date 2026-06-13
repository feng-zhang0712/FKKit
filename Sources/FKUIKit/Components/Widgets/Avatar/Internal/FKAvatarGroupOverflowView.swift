import UIKit

/// Neutral "+N" overflow chip styled for ``FKAvatarGroup`` (FKTag neutral equivalent).
final class FKAvatarGroupOverflowView: UIControl {
  private let label = UILabel()

  var overflowCount: Int = 0 {
    didSet { refreshLabel() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .button
    backgroundColor = .secondarySystemFill
    layer.cornerCurve = .continuous

    label.font = .systemFont(ofSize: 12, weight: .semibold)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.adjustsFontForContentSizeCategory = true
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.height / 2
  }

  override var intrinsicContentSize: CGSize {
    let textWidth = label.intrinsicContentSize.width
    let diameter = max(28, textWidth + 12)
    return CGSize(width: diameter, height: max(28, bounds.height > 0 ? bounds.height : 28))
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    let minSide: CGFloat = 44
    let w = max(bounds.width, minSide)
    let h = max(bounds.height, minSide)
    let hit = CGRect(x: bounds.midX - w / 2, y: bounds.midY - h / 2, width: w, height: h)
    return hit.contains(point)
  }

  func apply(diameter: CGFloat) {
    bounds.size = CGSize(width: max(diameter, intrinsicContentSize.width), height: diameter)
    label.font = .systemFont(ofSize: max(10, diameter * 0.34), weight: .semibold)
    invalidateIntrinsicContentSize()
  }

  private func refreshLabel() {
    label.text = "+\(overflowCount)"
    accessibilityLabel = FKAvatarI18n.overflowMembers(count: overflowCount)
    invalidateIntrinsicContentSize()
  }
}
