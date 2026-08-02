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
  private var lineStackView: UIStackView?
  private var customContentContainer: UIView?
  private var dotViews: [UIView] = []
  private var lineSegments: [UIView] = []
  private var lineWidthConstraints: [NSLayoutConstraint] = []
  private var lineHeightConstraints: [NSLayoutConstraint] = []
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

  /// Invoked with a logical page index when the user taps a selectable indicator target.
  var onPageSelected: ((Int) -> Void)?

  private var tapRecognizer: UITapGestureRecognizer?

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
    syncInteractionEnabled()
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard isUserInteractionEnabled else { return false }
    return bounds.insetBy(dx: -4, dy: -14).contains(point)
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
    syncInteractionEnabled()
  }

  private func syncInteractionEnabled() {
    let supportsSelection: Bool
    switch configuration.style {
    case .dots, .line, .bar:
      supportsSelection = configuration.allowsPageSelection && pageCount > 1
    case .fraction, .custom, .none:
      supportsSelection = false
    }
    isUserInteractionEnabled = supportsSelection

    if supportsSelection {
      if tapRecognizer == nil {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(recognizer)
        tapRecognizer = recognizer
      }
    } else if let tapRecognizer {
      removeGestureRecognizer(tapRecognizer)
      self.tapRecognizer = nil
    }
  }

  @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    let point = recognizer.location(in: self)
    guard let index = pageIndex(at: point) else { return }
    onPageSelected?(index)
  }

  private func pageIndex(at point: CGPoint) -> Int? {
    switch configuration.style {
    case .dots:
      return nearestSegmentIndex(at: point, segments: dotViews)
    case .line:
      return nearestSegmentIndex(at: point, segments: lineSegments)
    case .bar:
      guard let barTrack, barTrack.bounds.width > 0, pageCount > 0 else { return nil }
      let local = convert(point, to: barTrack)
      guard barTrack.bounds.insetBy(dx: -8, dy: -12).contains(local) else { return nil }
      let fraction = min(1, max(0, local.x / barTrack.bounds.width))
      return min(pageCount - 1, Int(fraction * CGFloat(pageCount)))
    case .fraction, .custom, .none:
      return nil
    }
  }

  private func nearestSegmentIndex(at point: CGPoint, segments: [UIView]) -> Int? {
    guard !segments.isEmpty else { return nil }
    var bestIndex: Int?
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for (index, segment) in segments.enumerated() {
      let frame = segment.convert(segment.bounds, to: self).insetBy(dx: -10, dy: -14)
      if frame.contains(point) {
        return index
      }
      let center = CGPoint(x: frame.midX, y: frame.midY)
      let distance = hypot(center.x - point.x, center.y - point.y)
      if distance < bestDistance {
        bestDistance = distance
        bestIndex = index
      }
    }
    return bestDistance <= 28 ? bestIndex : nil
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
    lineWidthConstraints.removeAll()
    lineHeightConstraints.removeAll()
    lineStackView?.removeFromSuperview()
    lineStackView = nil
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
    let thickness = max(configuration.lineThickness, 1)

    if lineContainer == nil {
      let container = UIView()
      container.translatesAutoresizingMaskIntoConstraints = false
      addSubview(container)
      NSLayoutConstraint.activate([
        container.centerXAnchor.constraint(equalTo: centerXAnchor),
        container.centerYAnchor.constraint(equalTo: centerYAnchor),
        container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
        container.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
        container.heightAnchor.constraint(equalToConstant: thickness),
      ])
      lineContainer = container
    }

    if lineStackView == nil, let lineContainer {
      let stack = UIStackView()
      stack.axis = .horizontal
      stack.alignment = .center
      stack.distribution = .fill
      stack.translatesAutoresizingMaskIntoConstraints = false
      lineContainer.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: lineContainer.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: lineContainer.trailingAnchor),
        stack.topAnchor.constraint(equalTo: lineContainer.topAnchor),
        stack.bottomAnchor.constraint(equalTo: lineContainer.bottomAnchor),
      ])
      lineStackView = stack
    }

    lineStackView?.spacing = configuration.dotSpacing

    guard lineSegments.count != pageCount else {
      updateLineSegmentMetrics()
      return
    }

    lineStackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
    lineSegments.removeAll()
    lineWidthConstraints.removeAll()
    lineHeightConstraints.removeAll()
    guard pageCount > 0, let lineStackView else { return }

    let cornerRadius = thickness / 2
    for _ in 0..<pageCount {
      let segment = UIView()
      segment.backgroundColor = configuration.inactiveColor
      segment.layer.cornerRadius = cornerRadius
      segment.translatesAutoresizingMaskIntoConstraints = false
      let width = segment.widthAnchor.constraint(equalToConstant: configuration.inactiveLineWidth)
      let height = segment.heightAnchor.constraint(equalToConstant: thickness)
      NSLayoutConstraint.activate([width, height])
      lineStackView.addArrangedSubview(segment)
      lineSegments.append(segment)
      lineWidthConstraints.append(width)
      lineHeightConstraints.append(height)
    }
  }

  private func updateLineSegmentMetrics() {
    let thickness = max(configuration.lineThickness, 1)
    let cornerRadius = thickness / 2
    for (index, segment) in lineSegments.enumerated() {
      segment.layer.cornerRadius = cornerRadius
      if lineHeightConstraints.indices.contains(index) {
        lineHeightConstraints[index].constant = thickness
      }
    }
  }

  private func updateLinePresentation(effectivePage: CGFloat, animated: Bool) {
    let activeWidth = max(configuration.activeLineWidth, configuration.inactiveLineWidth)
    let inactiveWidth = configuration.inactiveLineWidth
    let updates = {
      for (index, segment) in self.lineSegments.enumerated() {
        let distance = abs(CGFloat(index) - effectivePage)
        let focus = max(0, 1 - min(1, distance))
        let width = inactiveWidth + (activeWidth - inactiveWidth) * focus
        if self.lineWidthConstraints.indices.contains(index) {
          self.lineWidthConstraints[index].constant = width
        }
        segment.backgroundColor = focus > 0.5
          ? self.configuration.activeColor
          : self.configuration.inactiveColor
      }
      self.lineStackView?.layoutIfNeeded()
    }
    if shouldAnimateIndicator(animated: animated) {
      UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction], animations: updates)
    } else {
      updates()
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
      updateLinePresentation(effectivePage: effectivePage, animated: animated)

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
