import UIKit

/// Host-defined customization hooks for ``FKTabBar`` rendering and layout.
///
/// Subclass ``FKTabBarDefaultCustomization`` and override only the methods you need.
/// Assign the instance to ``FKTabBar/customization``.
@MainActor
public protocol FKTabBarCustomization: AnyObject {
  /// Overrides width for a visible item index; return `nil` to use ``FKTabBarLayoutConfiguration/widthMode``.
  func customWidth(for index: Int, item: FKTabBarItem, in tabBar: FKTabBar) -> CGFloat?
  /// Overrides spacing after a visible index; return `nil` to use ``FKTabBarLayoutConfiguration/itemSpacing``.
  func customSpacing(after index: Int, context: FKTabBarLayoutConfiguration.SpacingContext) -> CGFloat?
  /// Supplies a trailing accessory view; return `nil` to use built-in chevron rendering when applicable.
  func customAccessoryView(for item: FKTabBarItem, isSelected: Bool, isExpanded: Bool) -> UIView?
  /// Supplies a custom badge view for items using ``FKTabBarBadgeContent/custom``.
  func customBadgeView(for item: FKTabBarItem) -> UIView?
  /// Supplies custom tab content for items using ``FKTabBarItem/customContentIdentifier``.
  func customContentView(for item: FKTabBarItem) -> UIView?
  /// Post-configures each internal ``FKButton`` after default styling is applied.
  func configure(button: FKButton, item: FKTabBarItem, isSelected: Bool)
  /// Runs custom interaction animations on the tab button before selection commits.
  func animateInteraction(on button: FKButton, phase: FKTabBar.ItemInteractionPhase, item: FKTabBarItem)
  /// Supplies a custom indicator view for ``FKTabBarIndicatorStyle/custom``.
  func customIndicatorView(id: String) -> UIView?
  /// Draws or updates a custom indicator inside the provided container during layout.
  func renderCustomIndicator(id: String, bounds: CGRect, container: UIView)
  /// Overrides indicator geometry; return `nil` to use the built-in frame calculator.
  func customIndicatorFrame(itemFrame: CGRect, containerBounds: CGRect) -> CGRect?
  /// Resolves follow behavior for ``FKTabBarIndicatorFollowMode/custom`` styles.
  func indicatorFollowMode(forCustomID id: String) -> FKTabBarIndicatorFollowMode?
}

/// Default empty customization — override selectively in a subclass.
@MainActor
open class FKTabBarDefaultCustomization: FKTabBarCustomization {
  public init() {}

  open func customWidth(for index: Int, item: FKTabBarItem, in tabBar: FKTabBar) -> CGFloat? { nil }
  open func customSpacing(after index: Int, context: FKTabBarLayoutConfiguration.SpacingContext) -> CGFloat? { nil }
  open func customAccessoryView(for item: FKTabBarItem, isSelected: Bool, isExpanded: Bool) -> UIView? { nil }
  open func customBadgeView(for item: FKTabBarItem) -> UIView? { nil }
  open func customContentView(for item: FKTabBarItem) -> UIView? { nil }
  open func configure(button: FKButton, item: FKTabBarItem, isSelected: Bool) {}
  open func animateInteraction(on button: FKButton, phase: FKTabBar.ItemInteractionPhase, item: FKTabBarItem) {}
  open func customIndicatorView(id: String) -> UIView? { nil }
  open func renderCustomIndicator(id: String, bounds: CGRect, container: UIView) {}
  open func customIndicatorFrame(itemFrame: CGRect, containerBounds: CGRect) -> CGRect? { nil }
  open func indicatorFollowMode(forCustomID id: String) -> FKTabBarIndicatorFollowMode? { nil }
}
