import UIKit

/// Progress slider with an integrated buffered-range track (single chrome node for transport bars).
@MainActor
final class FKVideoBufferedProgressSlider: UIView {

  private let trackBackgroundView = UIView()
  private let bufferFillView = UIView()
  private let slider = UISlider()

  var bufferProgress: Float = 0 {
    didSet {
      bufferFillView.isHidden = bufferProgress <= 0
      setNeedsLayout()
    }
  }

  var value: Float { slider.value }

  var isEnabled: Bool {
    get { slider.isEnabled }
    set {
      slider.isEnabled = newValue
      isUserInteractionEnabled = newValue
    }
  }

  override var accessibilityLabel: String? {
    get { slider.accessibilityLabel }
    set { slider.accessibilityLabel = newValue }
  }

  override var accessibilityValue: String? {
    get { slider.accessibilityValue }
    set { slider.accessibilityValue = newValue }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    isAccessibilityElement = false
    trackBackgroundView.isUserInteractionEnabled = false
    trackBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    trackBackgroundView.layer.cornerRadius = 1.5
    bufferFillView.isUserInteractionEnabled = false
    bufferFillView.backgroundColor = UIColor.white.withAlphaComponent(0.35)
    bufferFillView.layer.cornerRadius = 1.5
    addSubview(trackBackgroundView)
    addSubview(bufferFillView)
    addSubview(slider)
    slider.minimumValue = 0
    slider.maximumValue = 1
    slider.isAccessibilityElement = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    slider.frame = bounds
    let trackHeight: CGFloat = 3
    let horizontalInset: CGFloat = 2
    let trackY = (bounds.height - trackHeight) / 2
    let trackWidth = max(0, bounds.width - horizontalInset * 2)
    trackBackgroundView.frame = CGRect(x: horizontalInset, y: trackY, width: trackWidth, height: trackHeight)
    let fillWidth = trackWidth * CGFloat(min(1, max(0, bufferProgress)))
    bufferFillView.frame = CGRect(x: horizontalInset, y: trackY, width: fillWidth, height: trackHeight)
  }

  func setValue(_ value: Float, animated: Bool = false) {
    slider.setValue(value, animated: animated)
  }

  func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
    slider.addTarget(target, action: action, for: controlEvents)
  }
}
