import UIKit

/// Background chrome for search controls (solid color, blur, border, underline).
@MainActor
final class FKSearchChromeView: UIView {
  private var blurView: FKBlurView?
  private var underlineView: UIView?
  private let borderLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    clipsToBounds = true

    borderLayer.fillColor = UIColor.clear.cgColor
    layer.addSublayer(borderLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func apply(
    appearance: FKSearchAppearanceConfiguration,
    layout: FKSearchLayoutConfiguration,
    barHeight: CGFloat,
    isFocused: Bool,
    isEnabled: Bool,
    underlineFrame: CGRect?
  ) {
    let cornerRadius = FKSearchLayoutEngine.resolvedCornerRadius(
      layout: layout,
      appearance: appearance,
      barHeight: barHeight
    )
    layer.cornerRadius = cornerRadius

    let state = resolvedStateAppearance(
      appearance: appearance,
      isFocused: isFocused,
      isEnabled: isEnabled
    )

    switch appearance.backgroundMaterial {
    case .none:
      releaseBlurView()
      backgroundColor = .clear
    case .solid:
      releaseBlurView()
      backgroundColor = state.backgroundColor ?? appearance.backgroundColor
    case let .blur(configuration):
      let blur = ensureBlurView()
      blur.frame = bounds
      blur.layer.cornerRadius = cornerRadius
      blur.clipsToBounds = true
      blur.configuration = configuration
      backgroundColor = .clear
    }

    if let border = appearance.border {
      borderLayer.isHidden = false
      borderLayer.strokeColor = (state.borderColor ?? border.color).cgColor
      borderLayer.lineWidth = border.width
      borderLayer.path = UIBezierPath(
        roundedRect: bounds.insetBy(dx: border.width / 2, dy: border.width / 2),
        cornerRadius: cornerRadius
      ).cgPath
    } else {
      borderLayer.isHidden = true
    }

    if let underlineFrame {
      let underline = ensureUnderlineView()
      underline.isHidden = false
      underline.frame = underlineFrame
      underline.backgroundColor = state.borderColor ?? appearance.tintColor.withAlphaComponent(0.35)
    } else {
      releaseUnderlineView()
    }
  }

  private func ensureBlurView() -> FKBlurView {
    if let blurView { return blurView }
    let view = FKBlurView(frame: bounds)
    view.translatesAutoresizingMaskIntoConstraints = true
    insertSubview(view, at: 0)
    blurView = view
    return view
  }

  private func releaseBlurView() {
    blurView?.removeFromSuperview()
    blurView = nil
  }

  private func ensureUnderlineView() -> UIView {
    if let underlineView { return underlineView }
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = true
    addSubview(view)
    underlineView = view
    return view
  }

  private func releaseUnderlineView() {
    underlineView?.removeFromSuperview()
    underlineView = nil
  }

  private func resolvedStateAppearance(
    appearance: FKSearchAppearanceConfiguration,
    isFocused: Bool,
    isEnabled: Bool
  ) -> FKSearchBarStateAppearance {
    if !isEnabled { return appearance.stateAppearances.disabled }
    if isFocused { return appearance.stateAppearances.focused }
    return appearance.stateAppearances.normal
  }
}
