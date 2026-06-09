import UIKit

/// Renders carousel page indicators (dots, bar, fraction, line).
@MainActor
final class FKCarouselPageIndicatorView: UIView {
  private enum InstalledStyle: Equatable {
    case none
    case dots
    case bar
    case fraction
    case line
    case custom
  }

  private var stackView: UIStackView?
  private var fractionLabel: UILabel?
  private var barTrack: UIView?
  private var barFill: UIView?
  private var lineContainer: UIView?
  private var customContentContainer: UIView?
  private var dotViews: [UIView] = []
  private var lineSegments: [UIView] = []
  private var installedStyle: InstalledStyle = .none

  var configuration: FKCarouselIndicatorConfiguration = .init() {
    didSet { rebuildIfNeeded() }
  }

  var pageCount: Int = 0 {
    didSet { rebuildIfNeeded() }
  }

  var currentPage: Int = 0 {
    didSet { updatePresentation(animated: animatesIndicatorDots) }
  }

  /// Logical page index derived from scroll offset during dragging.
  var scrollFromLogicalPage: Int = 0 {
    didSet { updatePresentation(animated: false) }
  }

  /// Logical destination page while dragging between pages.
  var scrollToLogicalPage: Int = 0

  var scrollProgress: CGFloat = 0 {
    didSet { updatePresentation(animated: false) }
  }

  var customRenderer: ((_ view: UIView, _ pageCount: Int, _ progress: CGFloat) -> Void)?

  /// When `false`, dot and bar transitions update without animation.
  var animatesIndicatorDots: Bool = true

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    isUserInteractionEnabled = false
    backgroundColor = .clear
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard configuration.style == .bar, let barTrack, barTrack.bounds.width > 0 else { return }
    updateBarFillProgress(animated: false)
  }

  private func updateBarFillProgress(animated: Bool) {
    guard let barTrack, let barFill, barTrack.bounds.width > 0 else { return }
    let fillProgress = barFillProgress()
    let targetWidth = barTrack.bounds.width * fillProgress
    let targetFrame = CGRect(x: 0, y: 0, width: targetWidth, height: barTrack.bounds.height)
    let updates = {
      barFill.frame = targetFrame
    }
    if shouldAnimateIndicator(animated: animated) {
      UIView.animate(withDuration: 0.2, animations: updates)
    } else {
      updates()
    }
  }

  private func shouldAnimateIndicator(animated: Bool) -> Bool {
    animated && animatesIndicatorDots && !UIAccessibility.isReduceMotionEnabled
  }

  private func barFillProgress() -> CGFloat {
    guard pageCount > 0 else { return 0 }
    if pageCount <= 1 { return 1 }
    let effectivePage = resolvedEffectivePage()
    return min(1, max(0, (effectivePage + 1) / CGFloat(pageCount)))
  }

  private func resolvedEffectivePage() -> CGFloat {
    if configuration.indicatorFollowsScrollProgress {
      if scrollProgress > 0, scrollFromLogicalPage != scrollToLogicalPage {
        return CGFloat(scrollFromLogicalPage) + scrollProgress
      }
      return CGFloat(scrollFromLogicalPage)
    }
    return CGFloat(currentPage)
  }

  func applyVisibility(pageCount: Int) {
    let shouldHide: Bool
    if pageCount <= 1 {
      shouldHide = configuration.hidesForSinglePage && !configuration.showsIndicatorForSinglePage
    } else {
      shouldHide = configuration.style == .none
    }
    isHidden = shouldHide
    accessibilityElementsHidden = configuration.hidesIndicatorFromAccessibility
  }

  private func installedStyle(for style: FKCarouselIndicatorStyle) -> InstalledStyle {
    switch style {
    case .dots: return .dots
    case .bar: return .bar
    case .fraction: return .fraction
    case .line: return .line
    case .custom: return .custom
    case .none: return .none
    }
  }

  private func rebuildIfNeeded() {
    let targetStyle = installedStyle(for: configuration.style)
    if targetStyle != installedStyle {
      tearDownInstalledStyleViews()
      installedStyle = targetStyle
    }

    switch configuration.style {
    case .dots:
      installDotsStyleIfNeeded()

    case .fraction:
      installFractionStyleIfNeeded()

    case .bar:
      installBarStyleIfNeeded()

    case .line:
      installLineStyleIfNeeded()

    case .custom:
      installCustomStyleIfNeeded()

    case .none:
      break
    }

    updatePresentation(animated: false)
    applyVisibility(pageCount: pageCount)
  }

  private func tearDownInstalledStyleViews() {
    stackView?.removeFromSuperview()
    stackView = nil
    dotViews.removeAll()

    fractionLabel?.removeFromSuperview()
    fractionLabel = nil

    barFill?.removeFromSuperview()
    barFill = nil
    barTrack?.removeFromSuperview()
    barTrack = nil

    lineSegments.removeAll()
    lineContainer?.removeFromSuperview()
    lineContainer = nil

    customContentContainer?.subviews.forEach { $0.removeFromSuperview() }
    customContentContainer?.removeFromSuperview()
    customContentContainer = nil
  }

  private func installDotsStyleIfNeeded() {
    if stackView == nil {
      let stack = UIStackView()
      stack.axis = .horizontal
      stack.alignment = .center
      stack.distribution = .equalCentering
      stack.translatesAutoresizingMaskIntoConstraints = false
      addSubview(stack)
      NSLayoutConstraint.activate([
        stack.centerXAnchor.constraint(equalTo: centerXAnchor),
        stack.centerYAnchor.constraint(equalTo: centerYAnchor),
      ])
      stackView = stack
    }

    stackView?.spacing = configuration.dotSpacing

    dotViews.forEach { $0.removeFromSuperview() }
    dotViews.removeAll()

    for _ in 0..<pageCount {
      let dot = UIView()
      dot.backgroundColor = configuration.inactiveColor
      dot.translatesAutoresizingMaskIntoConstraints = false
      dot.layer.cornerRadius = configuration.dotDiameter / 2
      NSLayoutConstraint.activate([
        dot.widthAnchor.constraint(equalToConstant: configuration.dotDiameter),
        dot.heightAnchor.constraint(equalToConstant: configuration.dotDiameter),
      ])
      stackView?.addArrangedSubview(dot)
      dotViews.append(dot)
    }
  }

  private func installFractionStyleIfNeeded() {
    guard fractionLabel == nil else { return }

    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
    fractionLabel = label
  }

  private func installBarStyleIfNeeded() {
    guard barTrack == nil else { return }

    let track = UIView()
    track.backgroundColor = configuration.inactiveColor.withAlphaComponent(0.35)
    track.layer.cornerRadius = 2
    track.translatesAutoresizingMaskIntoConstraints = false

    let fill = UIView()
    fill.backgroundColor = configuration.activeColor
    fill.layer.cornerRadius = 2
    track.addSubview(fill)

    addSubview(track)

    let trackLeading = track.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24)
    let trackTrailing = track.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
    trackLeading.priority = .defaultHigh
    trackTrailing.priority = .defaultHigh

    NSLayoutConstraint.activate([
      trackLeading,
      trackTrailing,
      track.centerYAnchor.constraint(equalTo: centerYAnchor),
      track.heightAnchor.constraint(equalToConstant: 4),
    ])

    barTrack = track
    barFill = fill
  }

  private func installLineStyleIfNeeded() {
    if lineContainer == nil {
      let container = UIView()
      container.translatesAutoresizingMaskIntoConstraints = false
      addSubview(container)

      let lineLeading = container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
      let lineTrailing = container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
      lineLeading.priority = .defaultHigh
      lineTrailing.priority = .defaultHigh

      NSLayoutConstraint.activate([
        lineLeading,
        lineTrailing,
        container.centerYAnchor.constraint(equalTo: centerYAnchor),
        container.heightAnchor.constraint(equalToConstant: 3),
      ])
      lineContainer = container
    }

    guard lineSegments.count != pageCount else { return }
    lineContainer?.subviews.forEach { $0.removeFromSuperview() }
    lineSegments.removeAll()
    guard pageCount > 0, let lineContainer else { return }

    let segmentStack = UIStackView()
    segmentStack.axis = .horizontal
    segmentStack.spacing = 4
    segmentStack.distribution = .fillEqually
    segmentStack.translatesAutoresizingMaskIntoConstraints = false
    lineContainer.addSubview(segmentStack)
    NSLayoutConstraint.activate([
      segmentStack.leadingAnchor.constraint(equalTo: lineContainer.leadingAnchor),
      segmentStack.trailingAnchor.constraint(equalTo: lineContainer.trailingAnchor),
      segmentStack.topAnchor.constraint(equalTo: lineContainer.topAnchor),
      segmentStack.bottomAnchor.constraint(equalTo: lineContainer.bottomAnchor),
    ])

    for _ in 0..<pageCount {
      let segment = UIView()
      segment.backgroundColor = configuration.inactiveColor
      segment.layer.cornerRadius = 1.5
      segmentStack.addArrangedSubview(segment)
      lineSegments.append(segment)
    }
  }

  private func installCustomStyleIfNeeded() {
    guard customContentContainer == nil else { return }

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .clear
    addSubview(container)
    NSLayoutConstraint.activate([
      container.leadingAnchor.constraint(equalTo: leadingAnchor),
      container.trailingAnchor.constraint(equalTo: trailingAnchor),
      container.topAnchor.constraint(equalTo: topAnchor),
      container.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    customContentContainer = container
  }

  private func updatePresentation(animated: Bool) {
    guard pageCount > 0 else { return }

    let effectivePage = resolvedEffectivePage()

    switch configuration.style {
    case .dots:
      for (index, dot) in dotViews.enumerated() {
        let distance = abs(CGFloat(index) - effectivePage)
        let isActive = distance < 0.5
        let targetColor = isActive ? configuration.activeColor : configuration.inactiveColor
        let targetScale: CGFloat = isActive && configuration.indicatorFollowsScrollProgress ? 1.15 : 1.0
        let updates = {
          dot.backgroundColor = targetColor
          dot.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
        }
        if shouldAnimateIndicator(animated: animated) {
          UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction], animations: updates)
        } else {
          updates()
        }
      }

    case .fraction:
      let current = min(max(0, currentPage), max(0, pageCount - 1))
      fractionLabel?.text = FKUIKitI18n.format(
        "fkuikit.carousel.indicator.fraction",
        current + 1,
        pageCount
      )

    case .bar:
      barTrack?.backgroundColor = configuration.inactiveColor.withAlphaComponent(0.35)
      barFill?.backgroundColor = configuration.activeColor
      updateBarFillProgress(animated: animated)

    case .line:
      for (index, segment) in lineSegments.enumerated() {
        segment.backgroundColor = index == currentPage ? configuration.activeColor : configuration.inactiveColor
      }

    case .custom:
      if let customContentContainer {
        customRenderer?(customContentContainer, pageCount, customRendererProgress())
      }

    case .none:
      break
    }
  }

  private func customRendererProgress() -> CGFloat {
    guard pageCount > 0 else { return 0 }
    if pageCount <= 1 { return 1 }
    let effectivePage = configuration.indicatorFollowsScrollProgress
      ? resolvedEffectivePage()
      : CGFloat(currentPage)
    return min(1, max(0, (effectivePage + 1) / CGFloat(pageCount)))
  }
}
