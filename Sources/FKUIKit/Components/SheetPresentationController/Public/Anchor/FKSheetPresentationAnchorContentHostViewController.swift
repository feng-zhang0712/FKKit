import UIKit

/// Hosts interchangeable anchor popup content and forwards ``preferredContentSize`` to the sheet layout engine.
///
/// Use this as the `contentController` passed to ``FKSheetPresentationController`` when you plan to call
/// ``FKSheetPresentationController/presentOrReplaceAnchorContent(from:contentController:replacement:presentAnimated:completion:)``
/// or ``setAnchorContent(_:transition:animateLayout:layoutAnimationDuration:completion:)`` on the same instance.
@MainActor
public final class FKSheetPresentationAnchorContentHostViewController: UIViewController {
  /// Content transition applied by ``setContent(_:transition:completion:)``.
  public typealias Transition = FKSheetPresentationAnchorContentTransition

  /// Whether a content transition is running.
  public private(set) var isTransitioningContent: Bool = false

  /// Called after ``preferredContentSize`` changes so the anchor host can relayout.
  public var onPreferredContentSizeDidChange: (() -> Void)?

  private var current: UIViewController?
  private var inFlightContent: UIViewController?
  private var pendingRequest: (UIViewController, Transition, (() -> Void)?)?
  private var coalescedCompletion: (() -> Void)?

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  /// Replaces the hosted child, optionally animating the swap and publishing the new preferred size immediately.
  public func setContent(
    _ content: UIViewController,
    transition: Transition = .none,
    completion: (() -> Void)? = nil
  ) {
    if isTransitioningContent {
      if inFlightContent === content {
        mergeCompletion(completion)
        return
      }
      if let existing = pendingRequest {
        pendingRequest = (content, transition, Self.chainCompletions(existing.2, completion))
      } else {
        pendingRequest = (content, transition, completion)
      }
      return
    }

    if current === content {
      preferredContentSize = content.preferredContentSize
      completion?()
      return
    }

    let previous = current
    isTransitioningContent = true
    inFlightContent = content

    addChild(content)
    content.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(content.view)
    NSLayoutConstraint.activate([
      content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      content.view.topAnchor.constraint(equalTo: view.topAnchor),
      content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    view.layoutIfNeeded()

    preferredContentSize = resolvedPreferredContentSize(for: content)
    onPreferredContentSizeDidChange?()

    let finalize: () -> Void = { [weak self] in
      guard let self else { return }
      previous?.willMove(toParent: nil)
      previous?.view.removeFromSuperview()
      previous?.removeFromParent()

      content.didMove(toParent: self)
      self.current = content
      self.inFlightContent = nil
      self.isTransitioningContent = false
      self.preferredContentSize = self.resolvedPreferredContentSize(for: content)
      self.onPreferredContentSizeDidChange?()

      let chained = self.coalescedCompletion
      self.coalescedCompletion = nil
      completion?()
      chained?()

      if let next = self.pendingRequest {
        self.pendingRequest = nil
        self.setContent(next.0, transition: next.1, completion: next.2)
      }
    }

    guard let previous else {
      finalize()
      return
    }
    if case .none = transition {
      finalize()
      return
    }

    previous.willMove(toParent: nil)

    switch transition {
    case .none:
      finalize()

    case let .crossfade(duration):
      content.view.alpha = 0
      UIView.animate(
        withDuration: max(0, duration),
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
      ) {
        content.view.alpha = 1
        previous.view.alpha = 0
      } completion: { _ in
        previous.view.alpha = 1
        finalize()
      }

    case let .slideVertical(direction, duration):
      let height = max(1, self.view.bounds.height)
      let offset: CGFloat = (direction == .up) ? height : -height
      content.view.transform = CGAffineTransform(translationX: 0, y: offset)
      UIView.animate(
        withDuration: max(0, duration),
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
      ) {
        content.view.transform = .identity
        previous.view.transform = CGAffineTransform(translationX: 0, y: -offset * 0.35)
        previous.view.alpha = 0
      } completion: { _ in
        previous.view.transform = .identity
        previous.view.alpha = 1
        finalize()
      }
    }
  }

  public override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
    super.preferredContentSizeDidChange(forChildContentContainer: container)
    guard let current, container === current else { return }
    preferredContentSize = current.preferredContentSize
    onPreferredContentSizeDidChange?()
  }

  private func mergeCompletion(_ completion: (() -> Void)?) {
    guard let completion else { return }
    if let existing = coalescedCompletion {
      coalescedCompletion = {
        existing()
        completion()
      }
    } else {
      coalescedCompletion = completion
    }
  }

  private static func chainCompletions(_ first: (() -> Void)?, _ second: (() -> Void)?) -> (() -> Void)? {
    switch (first, second) {
    case (nil, nil): return nil
    case (let first?, nil): return first
    case (nil, let second?): return second
    case (let first?, let second?): return { first(); second() }
    }
  }

  private func resolvedPreferredContentSize(for content: UIViewController) -> CGSize {
    let preferred = content.preferredContentSize
    if preferred.height > 0 {
      return preferred
    }
    let targetWidth = max(1, view.bounds.width)
    let measured = content.view.systemLayoutSizeFitting(
      CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(width: preferred.width, height: max(1, measured.height))
  }
}
