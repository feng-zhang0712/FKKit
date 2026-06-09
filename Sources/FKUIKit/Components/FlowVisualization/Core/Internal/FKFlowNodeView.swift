import UIKit

@MainActor
final class FKFlowNodeView: UIView {
  private let fillLayer = CALayer()
  private var iconView: UIImageView?
  private var numberLabel: UILabel?
  private var activityIndicator: UIActivityIndicatorView?
  private var pulseAnimationKey = "fk.flow.node.pulse"
  private var isLoading = false

  var nodeShape: FKFlowNodeShape = .circle {
    didSet { setNeedsLayout() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    appearance: FKFlowNodeAppearance,
    icon: UIImage?,
    numberText: String?,
    iconTint: UIColor?,
    alphaMultiplier: CGFloat = 1
  ) {
    fillLayer.backgroundColor = appearance.fillColor.cgColor
    fillLayer.fk_applyBorder(appearance.border)
    fillLayer.opacity = Float(alphaMultiplier)

    if let shadow = appearance.shadow {
      layer.fk_applyShadow(shadow, path: nil)
    } else {
      layer.fk_applyShadow(.none, path: nil)
    }

    guard !isLoading else { return }

    let tint = iconTint ?? appearance.iconTint
    if let icon {
      removeNumberLabel()
      let view = ensureIconView()
      view.image = icon
      view.tintColor = tint
      view.isHidden = false
    } else if let numberText {
      removeIconView()
      let label = ensureNumberLabel()
      label.text = numberText
      label.textColor = tint
      label.isHidden = false
    } else {
      removeIconView()
      removeNumberLabel()
    }
  }

  func setLoading(_ loading: Bool, tint: UIColor = .systemBlue) {
    guard loading != isLoading else { return }
    isLoading = loading

    if loading {
      setPulsing(false)
      removeIconView()
      removeNumberLabel()
      let indicator = ensureActivityIndicator()
      indicator.color = tint
      indicator.isHidden = false
      indicator.startAnimating()
      bringSubviewToFront(indicator)
    } else {
      removeActivityIndicator()
    }
  }

  func setPulsing(_ pulsing: Bool) {
    guard !isLoading else {
      fillLayer.removeAnimation(forKey: pulseAnimationKey)
      return
    }
    guard pulsing else {
      fillLayer.removeAnimation(forKey: pulseAnimationKey)
      return
    }
    guard fillLayer.animation(forKey: pulseAnimationKey) == nil else { return }
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = 1
    animation.toValue = 1.08
    animation.duration = 0.9
    animation.autoreverses = true
    animation.repeatCount = .infinity
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    fillLayer.add(animation, forKey: pulseAnimationKey)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    fillLayer.frame = bounds
    if let iconView {
      iconView.frame = bounds.insetBy(dx: bounds.width * 0.22, dy: bounds.height * 0.22)
    }
    if let numberLabel {
      numberLabel.frame = bounds
    }
    if let activityIndicator {
      activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    switch nodeShape {
    case .circle:
      fillLayer.cornerRadius = bounds.width * 0.5
      layer.cornerRadius = bounds.width * 0.5
    case .roundedSquare:
      fillLayer.cornerRadius = 6
      layer.cornerRadius = 6
    case .pin:
      fillLayer.cornerRadius = bounds.width * 0.5
      layer.cornerRadius = bounds.width * 0.5
    }
  }

  private func commonInit() {
    isUserInteractionEnabled = false
    clipsToBounds = false
    layer.insertSublayer(fillLayer, at: 0)
  }

  private func ensureIconView() -> UIImageView {
    if let iconView { return iconView }
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    addSubview(view)
    self.iconView = view
    return view
  }

  private func ensureNumberLabel() -> UILabel {
    if let numberLabel { return numberLabel }
    let label = UILabel()
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 12, weight: .semibold)
    label.adjustsFontForContentSizeCategory = true
    addSubview(label)
    self.numberLabel = label
    return label
  }

  private func ensureActivityIndicator() -> UIActivityIndicatorView {
    if let activityIndicator { return activityIndicator }
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    addSubview(indicator)
    self.activityIndicator = indicator
    return indicator
  }

  private func removeIconView() {
    iconView?.removeFromSuperview()
    iconView = nil
  }

  private func removeNumberLabel() {
    numberLabel?.removeFromSuperview()
    numberLabel = nil
  }

  private func removeActivityIndicator() {
    activityIndicator?.stopAnimating()
    activityIndicator?.removeFromSuperview()
    activityIndicator = nil
  }
}
