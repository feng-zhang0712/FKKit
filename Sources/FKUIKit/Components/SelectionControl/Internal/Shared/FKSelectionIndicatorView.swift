import UIKit

/// Visual state rendered by ``FKSelectionIndicatorView``.
enum FKSelectionIndicatorPresentation: Equatable {
  case checkboxUnchecked
  case checkboxChecked
  case checkboxIndeterminate
  case checkboxDisabled
  case checkboxDisabledOn
  case checkboxDisabledIndeterminate
  case radioUnchecked
  case radioSelected
  case radioDisabled
  case radioDisabledOn
}

/// Draws checkbox (rounded square) or radio (ring + dot) indicators.
@MainActor
final class FKSelectionIndicatorView: UIView {
  var size: FKSelectionControlSize = .medium {
    didSet { invalidateIntrinsicContentSize(); setNeedsDisplay() }
  }

  var tint: FKSelectionControlTint = .blue {
    didSet { setNeedsDisplay() }
  }

  var presentation: FKSelectionIndicatorPresentation = .checkboxUnchecked {
    didSet { setNeedsDisplay() }
  }

  var cornerRadiusOverride: CGFloat?
  var uncheckedBorderColor: UIColor = FKSelectionControlTintResolver.defaultUncheckedBorder
  var uncheckedBorderWidth: CGFloat?
  var checkmarkColor: UIColor = .white
  var checkmarkImage: UIImage?
  var indeterminateImage: UIImage?
  var ringWidthOverride: CGFloat?
  var innerDotScale: CGFloat = 0.5
  var errorBorderColor: UIColor = .systemRed
  var showsError: Bool = false
  var disabledOnAlpha: CGFloat = 0.48

  private let glyphView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear
    isOpaque = false
    contentMode = .redraw
    isUserInteractionEnabled = false
    glyphView.contentMode = .scaleAspectFit
    glyphView.isUserInteractionEnabled = false
    addSubview(glyphView)
  }

  override var intrinsicContentSize: CGSize {
    let side = size.indicatorSide
    return CGSize(width: side, height: side)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let inset = size.indicatorSide * 0.18
    glyphView.frame = bounds.insetBy(dx: inset, dy: inset)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    context.clear(rect)
    switch presentation {
    case .checkboxUnchecked, .checkboxChecked, .checkboxIndeterminate,
         .checkboxDisabled, .checkboxDisabledOn, .checkboxDisabledIndeterminate:
      drawCheckbox(in: bounds, context: context)
    case .radioUnchecked, .radioSelected, .radioDisabled, .radioDisabledOn:
      drawRadio(in: bounds, context: context)
    }
    updateGlyph()
  }

  // MARK: - Checkbox

  private func drawCheckbox(in rect: CGRect, context: CGContext) {
    let side = min(rect.width, rect.height)
    let box = CGRect(
      x: rect.midX - side / 2,
      y: rect.midY - side / 2,
      width: side,
      height: side
    )
    let radius = cornerRadiusOverride ?? FKSelectionControlMetrics.cornerRadius(for: size)
    let path = UIBezierPath(roundedRect: box, cornerRadius: radius)
    let borderWidth = uncheckedBorderWidth ?? FKSelectionControlMetrics.uncheckedBorderWidth(for: size)
    let tintColor = FKSelectionControlTintResolver.color(for: tint)
    let disabledTint = FKSelectionControlTintResolver.disabledOnColor(for: tint, alpha: max(disabledOnAlpha, 0.35))

    switch presentation {
    case .checkboxUnchecked:
      UIColor.clear.setFill()
      path.fill()
      let border = showsError ? errorBorderColor : uncheckedBorderColor
      border.setStroke()
      path.lineWidth = borderWidth
      path.stroke()

    case .checkboxChecked:
      tintColor.setFill()
      path.fill()

    case .checkboxIndeterminate:
      tintColor.setFill()
      path.fill()

    case .checkboxDisabled:
      UIColor.clear.setFill()
      path.fill()
      FKSelectionControlTintResolver.disabledUncheckedBorder.setStroke()
      path.lineWidth = borderWidth
      path.stroke()

    case .checkboxDisabledOn, .checkboxDisabledIndeterminate:
      disabledTint.setFill()
      path.fill()

    default:
      break
    }
  }

  // MARK: - Radio

  private func drawRadio(in rect: CGRect, context: CGContext) {
    let side = min(rect.width, rect.height)
    let inset = (ringWidthOverride ?? FKSelectionControlMetrics.radioRingWidth(for: size)) / 2
    let ringRect = CGRect(
      x: rect.midX - side / 2 + inset,
      y: rect.midY - side / 2 + inset,
      width: side - inset * 2,
      height: side - inset * 2
    )
    let ringWidth = ringWidthOverride ?? FKSelectionControlMetrics.radioRingWidth(for: size)
    let tintColor = FKSelectionControlTintResolver.color(for: tint)
    let disabledTint = FKSelectionControlTintResolver.disabledOnColor(for: tint, alpha: max(disabledOnAlpha, 0.35))

    let ringPath = UIBezierPath(ovalIn: ringRect)
    ringPath.lineWidth = ringWidth

    switch presentation {
    case .radioUnchecked:
      UIColor.clear.setFill()
      ringPath.fill()
      let border = showsError ? errorBorderColor : uncheckedBorderColor
      border.setStroke()
      ringPath.stroke()

    case .radioSelected:
      tintColor.setStroke()
      ringPath.stroke()
      let dotSide = side * min(max(innerDotScale, 0.35), 0.6)
      let dotRect = CGRect(
        x: rect.midX - dotSide / 2,
        y: rect.midY - dotSide / 2,
        width: dotSide,
        height: dotSide
      )
      tintColor.setFill()
      UIBezierPath(ovalIn: dotRect).fill()

    case .radioDisabled:
      UIColor.clear.setFill()
      ringPath.fill()
      FKSelectionControlTintResolver.disabledUncheckedBorder.setStroke()
      ringPath.stroke()

    case .radioDisabledOn:
      disabledTint.setStroke()
      ringPath.stroke()
      let dotSide = side * min(max(innerDotScale, 0.35), 0.6)
      let dotRect = CGRect(
        x: rect.midX - dotSide / 2,
        y: rect.midY - dotSide / 2,
        width: dotSide,
        height: dotSide
      )
      disabledTint.setFill()
      UIBezierPath(ovalIn: dotRect).fill()

    default:
      break
    }
  }

  // MARK: - Glyph

  private func updateGlyph() {
    let showCheck: Bool
    let showIndeterminate: Bool
    switch presentation {
    case .checkboxChecked, .checkboxDisabledOn:
      showCheck = true
      showIndeterminate = false
    case .checkboxIndeterminate, .checkboxDisabledIndeterminate:
      showCheck = false
      showIndeterminate = true
    default:
      showCheck = false
      showIndeterminate = false
    }

    guard showCheck || showIndeterminate else {
      glyphView.isHidden = true
      glyphView.image = nil
      return
    }

    glyphView.isHidden = false
    glyphView.tintColor = checkmarkColor
    let pointSize = size.indicatorSide * 0.55
    let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)

    if showCheck {
      if let checkmarkImage {
        glyphView.image = checkmarkImage.withRenderingMode(.alwaysTemplate)
      } else {
        glyphView.image = UIImage(systemName: "checkmark", withConfiguration: config)?
          .withRenderingMode(.alwaysTemplate)
      }
    } else if showIndeterminate {
      if let indeterminateImage {
        glyphView.image = indeterminateImage.withRenderingMode(.alwaysTemplate)
      } else {
        glyphView.image = UIImage(systemName: "minus", withConfiguration: config)?
          .withRenderingMode(.alwaysTemplate)
      }
    }
  }

  /// Applies a selection animation to the indicator content.
  func animatePresentation(
    to newPresentation: FKSelectionIndicatorPresentation,
    style: FKSelectionControlSelectionAnimation,
    duration: TimeInterval,
    respectsReducedMotion: Bool
  ) {
    let reduced = respectsReducedMotion && UIAccessibility.isReduceMotionEnabled
    let effective: FKSelectionControlSelectionAnimation = reduced ? .none : style
    let capped = min(0.2, max(0, duration))

    switch effective {
    case .none:
      presentation = newPresentation
    case .crossfade:
      UIView.transition(
        with: self,
        duration: capped,
        options: [.transitionCrossDissolve, .allowUserInteraction]
      ) {
        self.presentation = newPresentation
      }
    case .scalePop:
      presentation = newPresentation
      transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
      UIView.animate(
        withDuration: capped,
        delay: 0,
        usingSpringWithDamping: 0.55,
        initialSpringVelocity: 0.8,
        options: [.allowUserInteraction]
      ) {
        self.transform = .identity
      }
    }
  }
}
