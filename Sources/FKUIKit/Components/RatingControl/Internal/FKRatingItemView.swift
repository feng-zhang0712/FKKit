import UIKit

@MainActor
final class FKRatingItemView: UIView {
  private let emptyImageView = UIImageView()
  private let filledImageView = UIImageView()
  private let fillMaskLayer = CALayer()

  var fillFraction: CGFloat = 0 {
    didSet {
      guard fillFraction != oldValue else { return }
      updateFillMask()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func applyImages(empty: UIImage?, filled: UIImage?) {
    emptyImageView.image = empty
    filledImageView.image = filled
  }

  func applyColors(empty: UIColor, filled: UIColor) {
    emptyImageView.tintColor = empty
    filledImageView.tintColor = filled
  }

  func setFillFraction(_ fraction: CGFloat, animated: Bool, duration: TimeInterval, timing: FKRatingTiming) {
    guard animated, duration > 0 else {
      fillFraction = fraction
      return
    }

    CATransaction.begin()
    CATransaction.setAnimationDuration(duration)
    CATransaction.setAnimationTimingFunction(timing.mediaTimingFunction())
    fillFraction = fraction
    CATransaction.commit()
  }

  func performSelectionAnimation(_ style: FKRatingSelectionAnimation) {
    guard style == .bounce else { return }
    transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
    UIView.animate(
      withDuration: 0.22,
      delay: 0,
      usingSpringWithDamping: 0.62,
      initialSpringVelocity: 0.4,
      options: [.allowUserInteraction, .beginFromCurrentState]
    ) {
      self.transform = .identity
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    emptyImageView.frame = bounds
    filledImageView.frame = bounds
    updateFillMask()
  }

  private func commonInit() {
    isUserInteractionEnabled = false
    clipsToBounds = false
    emptyImageView.contentMode = .scaleAspectFit
    filledImageView.contentMode = .scaleAspectFit
    addSubview(emptyImageView)
    addSubview(filledImageView)
    filledImageView.layer.mask = fillMaskLayer
    fillMaskLayer.backgroundColor = UIColor.black.cgColor
  }

  private func updateFillMask() {
    let width = bounds.width * fillFraction
    fillMaskLayer.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
  }
}
