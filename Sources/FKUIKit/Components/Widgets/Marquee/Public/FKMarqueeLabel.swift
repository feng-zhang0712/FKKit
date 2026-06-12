import FKCoreKit
import UIKit

/// Single-line horizontal ticker label that scrolls when text exceeds the available width.
///
/// Supports drag-to-pause, Reduce Motion fallback, optional edge fading, and lifecycle-aware scrolling.
@MainActor
public final class FKMarqueeLabel: UIView {
  public static var defaultConfiguration: FKMarqueeLabelConfiguration {
    get { FKMarqueeLabelDefaults.configuration }
    set { FKMarqueeLabelDefaults.configuration = newValue }
  }

  public var configuration: FKMarqueeLabelConfiguration = FKMarqueeLabel.defaultConfiguration {
    didSet {
      guard oldValue != configuration else { return }
      reloadMarquee()
    }
  }

  /// Text displayed by the marquee; scrolling starts only when this exceeds the view width.
  public var text: String = "" {
    didSet {
      guard oldValue != text else { return }
      reloadMarquee()
    }
  }

  /// Programmatic pause; scrolling resumes when set to `false` (if motion is allowed).
  public var isPaused: Bool = false {
    didSet {
      guard oldValue != isPaused else { return }
      updateScrollState(applyStartDelay: false)
    }
  }

  private let clipContainer = UIView()
  private let scrollContentView = UIView()
  private let primaryLabel = UILabel()
  private let duplicateLabel = UILabel()
  private let staticLabel = UILabel()

  private let scrollDriver = FKMarqueeScrollDriver()
  private let loopDelayWork = FKCancellableDelayedWork(queue: .main)

  private var contentOffset: CGFloat = 0
  private var textWidth: CGFloat = 0
  private var segmentWidth: CGFloat = 0
  private var needsMarquee = false
  private var isPausedByUser = false
  private var isAppActive = true
  private var isStartDelayPending = false
  private var resolvedFont: UIFont = .preferredFont(forTextStyle: .subheadline)
  private var panGestureRecognizer: UIPanGestureRecognizer?

  /// Stored as `nonisolated(unsafe)` so tokens can be removed from `deinit` under Swift 6 isolation rules.
  nonisolated(unsafe) private var notificationTokens: [NSObjectProtocol] = []

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKMarqueeLabelConfiguration = FKMarqueeLabel.defaultConfiguration,
    text: String = ""
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.text = text
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: ceil(resolvedFont.lineHeight))
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let wasMarquee = needsMarquee
    evaluateMarqueeNeed(force: false)
    layoutLabels()
    FKMarqueeFadeMaskLayer.apply(fadeWidth: configuration.animation.fadeWidth, to: clipContainer)

    if wasMarquee != needsMarquee {
      updateScrollState(applyStartDelay: true)
    } else if !canScroll {
      stopScrolling(resetDelay: true)
    } else if needsMarquee && !scrollDriver.isRunning && !isStartDelayPending {
      updateScrollState(applyStartDelay: true)
    }
    updateAccessibility()
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    updateScrollState()
  }

  public override var isHidden: Bool {
    didSet {
      guard isHidden != oldValue else { return }
      updateScrollState()
    }
  }

  public override var alpha: CGFloat {
    didSet {
      guard alpha != oldValue else { return }
      updateScrollState()
    }
  }

  public override var semanticContentAttribute: UISemanticContentAttribute {
    didSet {
      guard oldValue != semanticContentAttribute else { return }
      setNeedsLayout()
    }
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      reloadMarquee()
    } else if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      contentOffset = 0
      setNeedsLayout()
    } else if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      applyLabelAppearance()
    }
  }

  deinit {
    scrollDriver.tearDown()
    loopDelayWork.cancel()
    notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
  }

  private func commonInit() {
    clipsToBounds = false
    isAccessibilityElement = true
    accessibilityTraits = .staticText

    clipContainer.clipsToBounds = true
    addSubview(clipContainer)

    scrollContentView.clipsToBounds = false
    clipContainer.addSubview(scrollContentView)
    clipContainer.addSubview(staticLabel)

    [primaryLabel, duplicateLabel, staticLabel].forEach { label in
      label.numberOfLines = 1
      label.lineBreakMode = .byClipping
      label.backgroundColor = .clear
      label.isAccessibilityElement = false
      label.accessibilityElementsHidden = true
    }

    scrollContentView.addSubview(primaryLabel)
    scrollContentView.addSubview(duplicateLabel)

    scrollDriver.onFrame = { [weak self] delta in
      self?.advanceScroll(by: delta)
    }

    installObservers()
    installPanGestureIfNeeded()
    reloadMarquee()
  }

  private func installObservers() {
    let center = NotificationCenter.default
    let queue = OperationQueue.main

    notificationTokens.append(center.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: queue
    ) { [weak self] _ in
      self?.isAppActive = false
      self?.updateScrollState()
    })

    notificationTokens.append(center.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: queue
    ) { [weak self] _ in
      self?.isAppActive = true
      self?.updateScrollState()
    })

    notificationTokens.append(center.addObserver(
      forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil,
      queue: queue
    ) { [weak self] _ in
      self?.reloadMarquee()
    })
  }

  private func installPanGestureIfNeeded() {
    if let panGestureRecognizer {
      removeGestureRecognizer(panGestureRecognizer)
      self.panGestureRecognizer = nil
    }

    guard configuration.interaction.pausesOnPan else {
      isUserInteractionEnabled = false
      return
    }

    isUserInteractionEnabled = true
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.cancelsTouchesInView = false
    addGestureRecognizer(pan)
    panGestureRecognizer = pan
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard configuration.interaction.pausesOnPan else { return }
    switch gesture.state {
    case .began:
      isPausedByUser = true
      stopScrolling(resetDelay: false)
    case .ended, .cancelled, .failed:
      isPausedByUser = false
      updateScrollState(applyStartDelay: false)
    default:
      break
    }
  }

  private func reloadMarquee() {
    resolvedFont = resolveFont()
    applyLabelAppearance()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    evaluateMarqueeNeed(force: true)
    updateAccessibility()
    updateScrollState()
  }

  private func resolveFont() -> UIFont {
    if let override = configuration.appearance.fontOverride {
      return override
    }
    return UIFont.preferredFont(forTextStyle: configuration.appearance.textStyle)
  }

  private func applyLabelAppearance() {
    let color = configuration.appearance.textColor
    [primaryLabel, duplicateLabel, staticLabel].forEach { label in
      label.font = resolvedFont
      label.textColor = color
      label.text = text
    }
  }

  private func evaluateMarqueeNeed(force: Bool) {
    let width = bounds.width
    guard width > 0 else { return }

    textWidth = FKMarqueeTextMeasurement.singleLineWidth(for: text, font: resolvedFont)
    segmentWidth = textWidth + configuration.animation.loopGap

    let fits = FKMarqueeTextMeasurement.fitsSingleLine(text: text, font: resolvedFont, width: width)
    let reduceMotion = shouldRespectReduceMotion()
    let marqueeEligible = !text.isEmpty && !fits && !reduceMotion

    if force || needsMarquee != marqueeEligible {
      needsMarquee = marqueeEligible
      contentOffset = 0
      scrollContentView.transform = .identity
      layoutLabels()
    }
  }

  private func layoutLabels() {
    let height = max(bounds.height, ceil(resolvedFont.lineHeight))
    clipContainer.frame = bounds

    if needsMarquee {
      staticLabel.isHidden = true
      scrollContentView.isHidden = false

      primaryLabel.frame = CGRect(x: 0, y: 0, width: textWidth, height: height)
      duplicateLabel.frame = CGRect(x: segmentWidth, y: 0, width: textWidth, height: height)
      scrollContentView.frame = CGRect(x: 0, y: 0, width: segmentWidth + textWidth, height: height)
      applyScrollTransform()
    } else {
      scrollContentView.isHidden = true
      staticLabel.isHidden = text.isEmpty

      let labelWidth = min(textWidth, bounds.width)
      var originX: CGFloat = 0
      switch configuration.layout.alignment {
      case .leading:
        if effectiveUserInterfaceLayoutDirection == .rightToLeft {
          originX = max(0, bounds.width - labelWidth)
        } else {
          originX = 0
        }
      case .center:
        originX = max(0, (bounds.width - labelWidth) / 2)
      }
      staticLabel.frame = CGRect(x: originX, y: 0, width: max(labelWidth, bounds.width), height: height)
      staticLabel.lineBreakMode = shouldRespectReduceMotion() ? .byTruncatingTail : .byClipping
    }
  }

  private func updateScrollState(applyStartDelay: Bool = true) {
    installPanGestureIfNeeded()

    guard canScroll else {
      stopScrolling(resetDelay: true)
      layoutLabels()
      updateAccessibility()
      return
    }

    layoutLabels()

    if scrollDriver.isRunning {
      updateAccessibility()
      return
    }

    if applyStartDelay {
      scheduleScrollStartIfNeeded()
    } else {
      loopDelayWork.cancel()
      isStartDelayPending = false
      scrollDriver.start()
    }
    updateAccessibility()
  }

  private func scheduleScrollStartIfNeeded() {
    guard !scrollDriver.isRunning, !isStartDelayPending else { return }

    let delay = max(0, configuration.animation.delay)
    guard delay > 0 else {
      scrollDriver.start()
      return
    }

    isStartDelayPending = true
    loopDelayWork.schedule(after: delay) { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.isStartDelayPending = false
        guard self.canScroll else { return }
        self.scrollDriver.start()
      }
    }
  }

  private var canScroll: Bool {
    needsMarquee
      && bounds.width > 0
      && window != nil
      && !isHidden
      && alpha > 0.01
      && isAppActive
      && !isPaused
      && !isPausedByUser
      && !shouldRespectReduceMotion()
      && configuration.animation.speed > 0
  }

  private func stopScrolling(resetDelay: Bool) {
    scrollDriver.stop()
    if resetDelay {
      loopDelayWork.cancel()
      isStartDelayPending = false
    }
  }

  private func advanceScroll(by delta: TimeInterval) {
    guard segmentWidth > 0 else { return }
    let speed = max(0, configuration.animation.speed)
    let travel = speed * CGFloat(delta)
    let signedTravel = resolvedScrollDirection() == .left ? travel : -travel
    contentOffset += signedTravel

    while contentOffset >= segmentWidth {
      contentOffset -= segmentWidth
    }
    while contentOffset < 0 {
      contentOffset += segmentWidth
    }

    applyScrollTransform()
  }

  private func applyScrollTransform() {
    scrollContentView.transform = CGAffineTransform(translationX: -contentOffset, y: 0)
  }

  private func resolvedScrollDirection() -> FKMarqueeLabelDirection {
    let base = configuration.animation.direction
    guard configuration.animation.mirrorsDirectionInRTL else { return base }
    let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
    guard isRTL else { return base }
    switch base {
    case .left: return .right
    case .right: return .left
    }
  }

  private func shouldRespectReduceMotion() -> Bool {
    configuration.animation.respectsReducedMotion && UIAccessibility.isReduceMotionEnabled
  }

  private func updateAccessibility() {
    let labelText = configuration.accessibility.customLabel ?? text
    accessibilityLabel = labelText.isEmpty ? nil : labelText

    if needsMarquee && canScroll && configuration.accessibility.usesUpdatesFrequentlyTraitWhenScrolling {
      accessibilityTraits = [.staticText, .updatesFrequently]
    } else {
      accessibilityTraits = .staticText
    }
  }
}
