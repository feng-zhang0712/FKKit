import UIKit

/// Shared detent resolution and wrapper frame math for modal container and overlay hosts.
@MainActor
enum FKSheetPresentationLayoutEngine {
  /// Inputs required to resolve detents and presentation frames.
  struct Environment {
    let configuration: FKSheetPresentationConfiguration
    let containerBounds: CGRect
    let containerSafeAreaInsets: UIEdgeInsets
    let preferredContentSize: CGSize
    /// When set, used for Auto Layout fit-content measurement after preferred-size policies are applied.
    let contentViewForFitting: UIView?
  }

  /// Cached detent heights plus the clamped selected index.
  struct DetentState: Equatable {
    var resolvedHeights: [CGFloat]
    var selectedIndex: Int
  }

  /// Safe-area insets applied to the presentation shell for the active ``FKSafeAreaPolicy``.
  static func presentationSafeInsets(
    configuration: FKSheetPresentationConfiguration,
    containerSafeAreaInsets: UIEdgeInsets
  ) -> UIEdgeInsets {
    switch configuration.safeAreaPolicy {
    case .contentRespectsSafeArea, .shellExtendsToScreenBottomEdge:
      return .zero
    case .containerRespectsSafeArea:
      return containerSafeAreaInsets
    }
  }

  /// Vertical space available for sheet detents after safe-area policy is applied.
  static func availableHeight(for environment: Environment) -> CGFloat {
    let bounds = environment.containerBounds
    let safe = environment.containerSafeAreaInsets
    let subtractSafe = configurationUsesContainerSafeAreaForDetents(environment.configuration)
    return bounds.height - (subtractSafe ? (safe.top + safe.bottom) : 0)
  }

  static func recalculateDetents(
    environment: Environment,
    selectedIndex: Int
  ) -> DetentState {
    let available = availableHeight(for: environment)
    let heights = environment.configuration.sheet.detents.map {
      resolve(detent: $0, availableHeight: available, environment: environment)
    }
    let clamped = max(0, min(selectedIndex, max(0, heights.count - 1)))
    return DetentState(resolvedHeights: heights, selectedIndex: clamped)
  }

  static func resolve(
    detent: FKSheetPresentationDetent,
    availableHeight: CGFloat,
    environment: Environment
  ) -> CGFloat {
    let configuration = environment.configuration
    let value: CGFloat
    switch detent {
    case .fitContent:
      let maxHeight = availableHeight * configuration.sheet.maximumFitContentHeightFraction
      value = min(maxHeight, measuredFitContentHeight(environment: environment))
      return clampedContentHeightValue(value, environment: environment, appliesMinimumContentHeight: false)
    case let .fixed(points):
      value = min(availableHeight, max(0, points))
    case let .fraction(fraction):
      value = min(availableHeight, max(0, fraction) * availableHeight)
    case .medium:
      value = availableHeight * 0.5
    case .large:
      value = max(0, availableHeight - largeDetentEdgeGap(environment: environment))
    case .full:
      value = availableHeight
    }
    return clampedContentHeightValue(value, environment: environment)
  }

  static func resolvedSheetHeight(
    environment: Environment,
    detentState: DetentState
  ) -> CGFloat {
    if detentState.resolvedHeights.indices.contains(detentState.selectedIndex) {
      return detentState.resolvedHeights[detentState.selectedIndex]
    }
    let available = availableHeight(for: environment)
    let bounds = environment.containerBounds
    let fallback = min(bounds.height * 0.5, max(240, measuredFitContentHeight(environment: environment)))
    return clampedContentHeightValue(fallback, environment: environment)
  }

  static func resolvedSheetWidth(environment: Environment) -> CGFloat {
    let bounds = environment.containerBounds
    let safeInsets = presentationSafeInsets(
      configuration: environment.configuration,
      containerSafeAreaInsets: environment.containerSafeAreaInsets
    )
    let availableWidth = bounds.width - safeInsets.left - safeInsets.right
    switch environment.configuration.sheet.widthPolicy {
    case .fill:
      return bounds.width
    case let .fraction(value):
      return min(availableWidth, max(220, availableWidth * min(max(value, 0.2), 1)))
    case let .max(value):
      return min(availableWidth, max(220, value))
    }
  }

  static func wrapperFrame(
    environment: Environment,
    detentState: DetentState
  ) -> CGRect {
    let bounds = environment.containerBounds
    let safeInsets = presentationSafeInsets(
      configuration: environment.configuration,
      containerSafeAreaInsets: environment.containerSafeAreaInsets
    )
    let configuration = environment.configuration

    switch configuration.layout {
    case .bottomSheet(_):
      let height = resolvedSheetHeight(environment: environment, detentState: detentState)
      let width = resolvedSheetWidth(environment: environment)
      let x = (bounds.width - width) / 2
      let y = bounds.height - height - (configuration.safeAreaPolicy.positionsShellAtContainerBottomEdge ? 0 : safeInsets.bottom)
      return CGRect(x: x, y: y, width: width, height: height)
    case .topSheet(_):
      let height = resolvedSheetHeight(environment: environment, detentState: detentState)
      let width = resolvedSheetWidth(environment: environment)
      let x = (bounds.width - width) / 2
      let y: CGFloat = configuration.safeAreaPolicy.positionsShellAtContainerBottomEdge ? 0 : safeInsets.top
      return CGRect(x: x, y: y, width: width, height: height)
    case .center(_):
      return resolvedCenterFrame(environment: environment)
    case .anchor:
      return resolvedCenterFrame(environment: environment)
    case let .edge(edge):
      return edgeFrame(in: bounds, edge: edge)
    }
  }

  static func resolvedCenterFrame(environment: Environment) -> CGRect {
    let bounds = environment.containerBounds
    let safeInsets = presentationSafeInsets(
      configuration: environment.configuration,
      containerSafeAreaInsets: environment.containerSafeAreaInsets
    )
    let configuration = environment.configuration
    let margins = configuration.center.minimumMargins
    let maxWidth = bounds.width - (CGFloat(margins.leading + margins.trailing) + safeInsets.left + safeInsets.right)
    let maxHeight = bounds.height - (CGFloat(margins.top + margins.bottom) + safeInsets.top + safeInsets.bottom)

    let size: CGSize
    switch configuration.center.size {
    case let .fixed(fixed):
      size = .init(width: min(maxWidth, max(0, fixed.width)), height: min(maxHeight, max(0, fixed.height)))
    case let .fitted(maxSize):
      let contentW = max(220, environment.preferredContentSize.width)
      let contentH = max(220, measuredFitContentHeight(environment: environment))
      size = .init(
        width: min(maxWidth, min(maxSize.width, contentW)),
        height: min(maxHeight, min(maxSize.height, contentH))
      )
    }

    let originX = (bounds.width - size.width) / 2
    let originY = (bounds.height - size.height) / 2
    return CGRect(x: originX, y: originY, width: size.width, height: size.height)
  }

  /// Clamps a raw content height using sheet min/max and container safe-area bounds.
  static func clampedContentHeight(_ height: CGFloat, environment: Environment) -> CGFloat {
    clampedContentHeightValue(height, environment: environment, appliesMinimumContentHeight: true)
  }

  /// Measures the presented content height used by `.fitContent` and edge-pinned sheet layouts.
  ///
  /// - Parameter appliesLegacyFittingFloor: When `false`, skips the 180pt fitting fallback used only for
  ///   historical detent defaults. Top-sheet bottom pinning passes `false` so shell growth does not force
  ///   full-height content measurement.
  static func measuredContentHeight(
    for environment: Environment,
    appliesLegacyFittingFloor: Bool = true
  ) -> CGFloat {
    measuredFitContentHeight(environment: environment, appliesLegacyFittingFloor: appliesLegacyFittingFloor)
  }

  static func edgeFrame(in bounds: CGRect, edge: UIRectEdge) -> CGRect {
    let width = min(bounds.width * 0.85, 420)
    let height = min(bounds.height * 0.85, 640)
    if edge.contains(.left) {
      return CGRect(x: 0, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.right) {
      return CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.top) {
      return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
  }

  // MARK: - Private

  private static func configurationUsesContainerSafeAreaForDetents(
    _ configuration: FKSheetPresentationConfiguration
  ) -> Bool {
    configuration.safeAreaPolicy == .containerRespectsSafeArea
  }

  private static func largeDetentEdgeGap(environment: Environment) -> CGFloat {
    let extraGap: CGFloat = 8
    let safe = environment.containerSafeAreaInsets
    switch environment.configuration.layout {
    case .topSheet(_):
      let safeBottom = configurationUsesContainerSafeAreaForDetents(environment.configuration) ? 0 : safe.bottom
      return safeBottom + extraGap
    default:
      let safeTop = configurationUsesContainerSafeAreaForDetents(environment.configuration) ? 0 : safe.top
      return safeTop + extraGap
    }
  }

  private static func measuredFitContentHeight(
    environment: Environment,
    appliesLegacyFittingFloor: Bool = true
  ) -> CGFloat {
    let targetWidth = environment.containerBounds.width
    let preferred = environment.preferredContentSize.height
    let minimumMeasured: CGFloat = appliesLegacyFittingFloor ? 180 : 44

    switch environment.configuration.preferredContentSizePolicy {
    case .strict:
      if preferred > 0 { return max(minimumMeasured, preferred) }
    case .automatic:
      if preferred >= 44 { return preferred }
    case .ignore:
      break
    }

    guard let view = environment.contentViewForFitting else { return appliesLegacyFittingFloor ? 360 : 44.0 }
    let size = view.systemLayoutSizeFitting(
      CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return max(minimumMeasured, size.height)
  }

  private static func clampedContentHeightValue(
    _ height: CGFloat,
    environment: Environment,
    appliesMinimumContentHeight: Bool = true
  ) -> CGFloat {
    var value = max(44, height)
    if appliesMinimumContentHeight, let minimum = environment.configuration.sheet.minimumContentHeight {
      value = max(value, minimum)
    }
    if let maximum = environment.configuration.sheet.maximumContentHeight {
      value = min(value, maximum)
    }
    let safe = presentationSafeInsets(
      configuration: environment.configuration,
      containerSafeAreaInsets: environment.containerSafeAreaInsets
    )
    let maxAvailable = environment.containerBounds.height - safe.top - safe.bottom
    return min(value, maxAvailable)
  }
}
