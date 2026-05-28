import UIKit

public extension FKSheetPresentationConfiguration {
  /// Sheet-specific behavior and allowed heights.
  struct SheetConfiguration: Sendable {
    public enum WidthPolicy: Sendable, Equatable {
      /// Uses full container width.
      case fill
      /// Uses a fraction of container width and centers the sheet.
      case fraction(CGFloat)
      /// Uses full width until this max value, then centers.
      case max(CGFloat)
    }

    /// How swipe-to-dismiss eligibility is determined relative to detents during a single sheet pan.
    ///
    /// - Note: This only affects top/bottom sheet layouts when `dismissBehavior.allowsSwipe` is enabled.
    public enum CrossDetentSwipeDismissPolicy: Sendable, Equatable {
      /// Close to `UISheetPresentationController`: once the interactive geometry reaches the smallest detent,
      /// further drag in the dismiss direction can dismiss in the **same** gesture (no need to lift and pan again).
      case systemAligned
      /// Previous FK behavior: dismiss rubber-banding and end-of-gesture dismiss thresholds apply only when the
      /// sheet was already at the smallest resolved detent height **when the pan began**.
      case strictSmallestDetentAtPanStart
    }

    /// Backdrop tuning that reacts to detent state.
    public struct MultiStageBackdropConfiguration: Sendable, Equatable {
      /// Enables detent-based backdrop intensity updates.
      public var isEnabled: Bool
      /// Minimum backdrop alpha used at the smallest detent.
      public var minimumAlpha: CGFloat
      /// Maximum backdrop alpha used at the largest detent.
      public var maximumAlpha: CGFloat

      /// Creates multi-stage backdrop settings.
      public init(isEnabled: Bool = false, minimumAlpha: CGFloat = 0.15, maximumAlpha: CGFloat = 0.4) {
        self.isEnabled = isEnabled
        self.minimumAlpha = min(max(minimumAlpha, 0), 1)
        self.maximumAlpha = min(max(maximumAlpha, self.minimumAlpha), 1)
      }
    }

    /// Available stopping points for sheet modes.
    ///
    /// Array order is preserved for programmatic selection and callbacks. Gesture resolution compares
    /// resolved heights, so detents do not need to be sorted by size.
    public var detents: [FKSheetPresentationDetent]
    /// Selected detent index when the sheet first appears (aligned with ``UISheetPresentationController`` selection semantics).
    public var initialSelectedDetentIndex: Int
    /// Maximum height ratio used when resolving `.fitContent`.
    public var maximumFitContentHeightFraction: CGFloat
    /// Whether the sheet shows the system-like grabber handle (aligned with `UISheetPresentationController.prefersGrabberVisible`).
    public var prefersGrabberVisible: Bool
    /// Grabber size in points.
    public var grabberSize: CGSize
    /// Grabber top spacing in points.
    public var grabberTopInset: CGFloat
    /// Base dismiss distance (points) measured along the dismiss axis when the gesture ends at the smallest detent.
    ///
    /// This is a deliberate-pull guard, not a tap target. The default is higher than the HIG 44pt minimum so
    /// short accidental drags are less likely to dismiss. Use ``resolvedDismissThreshold(smallestDetentHeight:)``
    /// at runtime; it may raise this value when the smallest resolved detent is tall.
    public var dismissThreshold: CGFloat
    /// Velocity threshold for deciding whether a swipe should dismiss.
    public var dismissVelocityThreshold: CGFloat
    /// Scroll handoff strategy between content and sheet pan gestures.
    public var scrollTrackingStrategy: FKSheetScrollTrackingStrategy
    /// Enables magnetic snapping near detents.
    public var enablesMagneticSnapping: Bool
    /// Distance threshold (points) used by magnetic snapping.
    public var magneticSnapThreshold: CGFloat
    /// Optional minimum content height safety constraint.
    public var minimumContentHeight: CGFloat?
    /// Optional maximum content height safety constraint.
    public var maximumContentHeight: CGFloat?
    /// Width policy used by top/bottom sheet modes.
    public var widthPolicy: WidthPolicy
    /// Detent-aware backdrop behavior.
    public var multiStageBackdrop: MultiStageBackdropConfiguration
    /// Controls whether a single pan can dismiss after shrinking from a larger detent to the smallest detent.
    public var crossDetentSwipeDismissPolicy: CrossDetentSwipeDismissPolicy

    /// Creates a sheet configuration.
    public init(
      detents: [FKSheetPresentationDetent] = [.fitContent, .full],
      initialSelectedDetentIndex: Int = 0,
      maximumFitContentHeightFraction: CGFloat = 0.9,
      prefersGrabberVisible: Bool = true,
      grabberSize: CGSize = .init(width: 36, height: 5),
      grabberTopInset: CGFloat = 8,
      dismissThreshold: CGFloat = 80,
      dismissVelocityThreshold: CGFloat = 1200,
      scrollTrackingStrategy: FKSheetScrollTrackingStrategy = .automatic,
      enablesMagneticSnapping: Bool = true,
      magneticSnapThreshold: CGFloat = 28,
      minimumContentHeight: CGFloat? = nil,
      maximumContentHeight: CGFloat? = nil,
      widthPolicy: WidthPolicy = .fill,
      multiStageBackdrop: MultiStageBackdropConfiguration = .init(),
      crossDetentSwipeDismissPolicy: CrossDetentSwipeDismissPolicy = .systemAligned
    ) {
      self.detents = detents.isEmpty ? [.fitContent] : detents
      self.initialSelectedDetentIndex = max(0, min(initialSelectedDetentIndex, self.detents.count - 1))
      self.maximumFitContentHeightFraction = min(max(maximumFitContentHeightFraction, 0.2), 1)
      self.prefersGrabberVisible = prefersGrabberVisible
      self.grabberSize = grabberSize
      self.grabberTopInset = max(0, grabberTopInset)
      self.dismissThreshold = max(0, dismissThreshold)
      self.dismissVelocityThreshold = max(0, dismissVelocityThreshold)
      self.scrollTrackingStrategy = scrollTrackingStrategy
      self.enablesMagneticSnapping = enablesMagneticSnapping
      self.magneticSnapThreshold = max(0, magneticSnapThreshold)
      self.minimumContentHeight = minimumContentHeight
      self.maximumContentHeight = maximumContentHeight
      self.widthPolicy = widthPolicy
      self.multiStageBackdrop = multiStageBackdrop
      self.crossDetentSwipeDismissPolicy = crossDetentSwipeDismissPolicy
    }

    private static let dismissThresholdSmallestDetentFraction: CGFloat = 0.10
    private static let dismissThresholdMaximumCap: CGFloat = 120

    /// Effective dismiss distance for the current sheet geometry (base threshold, detent-aware scaling, capped).
    func resolvedDismissThreshold(smallestDetentHeight: CGFloat) -> CGFloat {
      let scaled = max(0, smallestDetentHeight) * Self.dismissThresholdSmallestDetentFraction
      return min(max(dismissThreshold, scaled), Self.dismissThresholdMaximumCap)
    }
  }

  /// Sizing rules for the `.center` mode.
  struct CenterConfiguration: Sendable, Equatable {
    /// Size strategy for centered presentation.
    public enum Size: Sendable, Equatable {
      /// Uses a fixed size.
      case fixed(CGSize)
      /// Uses content-fitting size clamped by maximum bounds.
      case fitted(maxSize: CGSize)
    }

    /// Size strategy.
    public var size: Size
    /// Minimum margins against container edges (useful for iPad / large screens).
    public var minimumMargins: NSDirectionalEdgeInsets
    /// Enables swipe-to-dismiss for center mode.
    public var dismissEnabled: Bool
    /// Progress threshold for center interactive dismissal.
    public var dismissProgressThreshold: CGFloat
    /// Velocity threshold for center interactive dismissal.
    public var dismissVelocityThreshold: CGFloat

    /// Creates a center configuration.
    public init(
      size: Size = .fitted(maxSize: .init(width: 460, height: 640)),
      minimumMargins: NSDirectionalEdgeInsets = .init(top: 24, leading: 24, bottom: 24, trailing: 24),
      dismissEnabled: Bool = false,
      dismissProgressThreshold: CGFloat = 0.35,
      dismissVelocityThreshold: CGFloat = 900
    ) {
      self.size = size
      self.minimumMargins = minimumMargins
      self.dismissEnabled = dismissEnabled
      self.dismissProgressThreshold = min(max(dismissProgressThreshold, 0.05), 0.95)
      self.dismissVelocityThreshold = max(0, dismissVelocityThreshold)
    }
  }

  /// Rotation handling strategy used when interface orientation changes.
  public enum RotationHandling: Sendable, Equatable {
    /// Relayouts and animates to the new frame when the container bounds change.
    case relayoutAnimated
    /// Relayouts without animation when the container bounds change.
    case relayoutImmediate
    /// Keeps the current on-screen frame when the container bounds change (for example during rotation).
    case ignore
  }

  /// Preferred content size policy when modes support intrinsic content.
  public enum PreferredContentSizePolicy: Sendable, Equatable {
    /// Uses `preferredContentSize` when it is at least 44pt; otherwise falls back to layout fitting.
    case automatic
    /// Ignores `preferredContentSize` and uses layout fitting for fit-content sizing.
    case ignore
    /// Uses `preferredContentSize` whenever it is greater than zero; otherwise falls back to layout fitting.
    case strict
  }
}
