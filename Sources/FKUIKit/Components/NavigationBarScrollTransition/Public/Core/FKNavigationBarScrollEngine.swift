import UIKit

/// Drives navigation-bar chrome from a scroll view’s vertical offset.
///
/// Attach via ``UIScrollView/fk_navigationBarScrollEngine`` or construct manually and assign
/// ``scrollView``. Bind a view controller when automatic ``UINavigationItem`` application or
/// status-bar updates are required.
///
/// This engine does **not** pin content views — use ``FKStickyEngine`` for sticky strips.
@MainActor
public final class FKNavigationBarScrollEngine: NSObject {
  /// Scroll view that drives progress. Held weakly.
  public weak var scrollView: UIScrollView? {
    didSet {
      guard oldValue !== scrollView else { return }
      tearDownObservation()
      if configuration.observesAutomatically {
        startObservationIfNeeded()
      }
      updateIfNeeded(force: true)
    }
  }

  /// Host view controller used for ``UINavigationItem`` application and status-bar updates. Held weakly.
  public weak var viewController: UIViewController? {
    didSet {
      guard oldValue !== viewController else { return }
      updateIfNeeded(force: true)
    }
  }

  /// Sendable transition policy.
  public var configuration: FKNavigationBarScrollConfiguration {
    didSet {
      syncObservationMode(from: oldValue)
      updateIfNeeded(force: true)
    }
  }

  /// Chrome at progress `0`.
  public var fromAppearance: FKNavigationBarScrollAppearance {
    didSet { updateIfNeeded(force: true) }
  }

  /// Chrome at progress `1`.
  public var toAppearance: FKNavigationBarScrollAppearance {
    didSet { updateIfNeeded(force: true) }
  }

  /// Invoked when progress changes by at least ``FKNavigationBarScrollConfiguration/progressEpsilon``.
  public var onProgressChange: ((FKNavigationBarScrollProgress) -> Void)?

  /// Invoked when the resolved appearance snapshot changes after a progress update.
  public var onAppearanceChange: ((FKNavigationBarScrollAppearance, CGFloat) -> Void)?

  /// Latest normalized progress.
  public private(set) var progress: FKNavigationBarScrollProgress = .start

  /// Latest interpolated appearance (continuous fields lerped; status bar discrete).
  public private(set) var resolvedAppearance: FKNavigationBarScrollAppearance

  /// Forced progress override, when set via ``forceProgress(_:)``.
  public private(set) var forcedProgress: CGFloat?

  private var observations: [NSKeyValueObservation] = []
  private var lastAppliedProgress: CGFloat = -1
  private var lastStatusBarBucket: Bool?
  private var didRequestUnderlapLayout = false
  private var isUpdating = false

  /// Creates an engine with the given configuration and endpoint appearances.
  public init(
    configuration: FKNavigationBarScrollConfiguration = .default,
    fromAppearance: FKNavigationBarScrollAppearance = .transparent(),
    toAppearance: FKNavigationBarScrollAppearance = .solid(backgroundColor: .systemBackground)
  ) {
    self.configuration = configuration
    self.fromAppearance = fromAppearance
    self.toAppearance = toAppearance
    self.resolvedAppearance = fromAppearance
    super.init()
  }

  // MARK: - Binding

  /// Binds `viewController` for navigation-item application and status-bar updates.
  public func bind(viewController: UIViewController?) {
    self.viewController = viewController
  }

  /// Binds both the driving scroll view and host view controller.
  public func bind(scrollView: UIScrollView?, viewController: UIViewController?) {
    self.scrollView = scrollView
    self.viewController = viewController
  }

  // MARK: - Controls

  /// Forces progress to `value` until ``clearForcedProgress()`` or ``reset(stopObserving:)``.
  public func forceProgress(_ value: CGFloat) {
    forcedProgress = min(max(value, 0), 1)
    updateIfNeeded(force: true)
  }

  /// Clears a previously forced progress and resumes scroll mapping.
  public func clearForcedProgress() {
    forcedProgress = nil
    updateIfNeeded(force: true)
  }

  /// Recomputes progress from the current scroll position (or forced value) and reapplies chrome.
  public func reload() {
    updateIfNeeded(force: true)
  }

  /// Forwards a scroll tick when ``FKNavigationBarScrollConfiguration/observesAutomatically`` is `false`.
  public func handleScroll() {
    updateIfNeeded(force: false)
  }

  /// Starts KVO observation when automatic mode is enabled.
  public func startObserving() {
    startObservationIfNeeded()
  }

  /// Stops KVO observation.
  public func stopObserving() {
    tearDownObservation()
  }

  /// Clears forced progress and optionally stops observation. Does not restore a previous bar style.
  public func reset(stopObserving stop: Bool = false) {
    forcedProgress = nil
    lastAppliedProgress = -1
    lastStatusBarBucket = nil
    didRequestUnderlapLayout = false
    progress = .start
    resolvedAppearance = fromAppearance
    if stop {
      tearDownObservation()
    }
    updateIfNeeded(force: true)
  }

  /// Convenience accessor for the status-bar style implied by the current progress.
  public var resolvedStatusBarStyle: UIStatusBarStyle {
    progress.resolvedStatusBarStyle(
      from: fromAppearance,
      to: toAppearance,
      threshold: configuration.discreteThreshold
    )
  }

  // MARK: - Observation

  private func syncObservationMode(from oldValue: FKNavigationBarScrollConfiguration) {
    guard oldValue.observesAutomatically != configuration.observesAutomatically else { return }
    if configuration.observesAutomatically {
      startObservationIfNeeded()
    } else {
      tearDownObservation()
    }
  }

  private func startObservationIfNeeded() {
    guard configuration.observesAutomatically, let scrollView else { return }
    guard observations.isEmpty else { return }
    observations = [
      scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
        self?.handleObservedScrollMetrics()
      },
      scrollView.observe(\.adjustedContentInset, options: [.new]) { [weak self] _, _ in
        self?.handleObservedScrollMetrics()
      },
    ]
  }

  /// UIScrollView metric KVO arrives on the main thread during tracking; update synchronously
  /// to avoid a one-frame chrome lag from hopping through `Task`.
  private nonisolated func handleObservedScrollMetrics() {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        updateIfNeeded(force: false)
      }
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.updateIfNeeded(force: false)
      }
    }
  }

  private func tearDownObservation() {
    observations.forEach { $0.invalidate() }
    observations.removeAll()
  }

  // MARK: - Update

  private func updateIfNeeded(force: Bool) {
    guard !isUpdating else { return }
    guard configuration.isEnabled || force else { return }

    isUpdating = true
    defer { isUpdating = false }

    let nextValue = resolveProgressValue()
    let progressDelta = abs(nextValue - lastAppliedProgress)
    guard force || progressDelta >= configuration.progressEpsilon || lastAppliedProgress < 0 else {
      return
    }

    let previousBucket = lastStatusBarBucket
    progress = FKNavigationBarScrollProgress(value: nextValue)
    resolvedAppearance = FKNavigationBarScrollAppearance.interpolated(
      from: fromAppearance,
      to: toAppearance,
      progress: nextValue,
      discreteThreshold: configuration.discreteThreshold
    )
    lastAppliedProgress = nextValue

    let statusBucket = nextValue >= configuration.discreteThreshold
    lastStatusBarBucket = statusBucket

    if configuration.appliesAppearanceAutomatically {
      applyResolvedAppearance()
    }

    onProgressChange?(progress)
    onAppearanceChange?(resolvedAppearance, nextValue)

    if configuration.updatesStatusBarAppearance,
       previousBucket != statusBucket || force {
      viewController?.setNeedsStatusBarAppearanceUpdate()
    }
  }

  private func resolveProgressValue() -> CGFloat {
    if let forcedProgress {
      return forcedProgress
    }
    guard let scrollView else { return 0 }
    let rawOffset: CGFloat
    if configuration.usesAdjustedContentOffset {
      rawOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    } else {
      rawOffset = scrollView.contentOffset.y
    }
    let span = configuration.endOffset - configuration.startOffset
    guard span > 0.5 else { return 0 }
    return min(max((rawOffset - configuration.startOffset) / span, 0), 1)
  }

  private func applyResolvedAppearance() {
    let appearance = resolvedAppearance
    let target = configuration.applicationTarget
    let navigationBar = viewController?.navigationController?.navigationBar

    FKNavigationBarScrollAppearanceApplicator.suppressSystemScrollEdgeEffect(on: scrollView)

    switch target {
    case .navigationItem:
      if let item = viewController?.navigationItem {
        FKNavigationBarScrollAppearanceApplicator.apply(appearance: appearance, to: item)
      }
      // Mirror onto the shared bar so an opaque root appearance cannot linger.
      FKNavigationBarScrollAppearanceApplicator.applySharedNavigationBar(
        appearance: appearance,
        navigationBar: navigationBar
      )
    case .navigationBar:
      if let navigationBar {
        FKNavigationBarScrollAppearanceApplicator.apply(appearance: appearance, to: navigationBar)
      }
    case .both:
      if let item = viewController?.navigationItem {
        FKNavigationBarScrollAppearanceApplicator.apply(appearance: appearance, to: item)
      }
      if let navigationBar {
        FKNavigationBarScrollAppearanceApplicator.apply(appearance: appearance, to: navigationBar)
      }
    }

    // Only when translucency flips. Requesting layout on every progress tick fights scrolling.
    let needsUnderlap = appearance.backgroundAlpha < 0.99
    if needsUnderlap != didRequestUnderlapLayout {
      didRequestUnderlapLayout = needsUnderlap
      if needsUnderlap {
        navigationBar?.superview?.setNeedsLayout()
        viewController?.view.setNeedsLayout()
      }
    }
  }
}
