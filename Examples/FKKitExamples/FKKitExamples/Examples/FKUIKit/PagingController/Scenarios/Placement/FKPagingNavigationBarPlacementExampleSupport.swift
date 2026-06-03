import UIKit
import FKUIKit

/// Tab items and pages for the navigation-bar placement showcase (mixed content styles in one strip).
enum FKPagingNavigationBarPlacementExampleSupport {
  /// Builds a scrollable nav-bar strip that mixes common tab content patterns.
  static func makeShowcaseTabs() -> [FKTabBarItem] {
    [
      FKTabBarItem(
        id: "home",
        title: .init(normal: .init(text: "Home")),
        image: .init(normal: .init(source: .systemSymbol(name: "house"))),
        accessibilityLabel: "Home"
      ),
      FKTabBarItem(
        id: "explore",
        title: .init(normal: .init(text: "Explore")),
        image: .init(normal: .init(source: .systemSymbol(name: "safari"))),
        accessibilityLabel: "Explore"
      ),
      FKTabBarItem(
        id: "inbox-dot",
        title: .init(normal: .init(text: "Inbox")),
        image: .init(normal: .init(source: .systemSymbol(name: "tray"))),
        badge: .init(state: .init(normal: .dot)),
        accessibilityLabel: "Inbox, unread"
      ),
      FKTabBarItem(
        id: "alerts-count",
        title: .init(normal: .init(text: "Alerts")),
        image: .init(normal: .init(source: .systemSymbol(name: "bell"))),
        badge: .init(state: .init(normal: .count(12))),
        accessibilityLabel: "Alerts, 12"
      ),
      FKTabBarItem(
        id: "short-go",
        title: .init(normal: .init(text: "Go")),
        accessibilityLabel: "Go"
      ),
      FKTabBarItem(
        id: "long-title",
        title: .init(normal: .init(text: "Very Long Financial Dashboard")),
        accessibilityLabel: "Very Long Financial Dashboard"
      ),
      FKTabBarItem(
        id: "icon-only-safari",
        title: .init(normal: .init(text: "")),
        image: .init(normal: .init(source: .systemSymbol(name: "safari"))),
        accessibilityLabel: "Safari"
      ),
      FKTabBarItem(
        id: "icon-only-heart",
        title: .init(normal: .init(text: "")),
        image: .init(normal: .init(source: .systemSymbol(name: "heart"))),
        badge: .init(state: .init(normal: .dot)),
        accessibilityLabel: "Favorites"
      ),
      FKTabBarItem(
        id: "trailing-icon",
        title: .init(normal: .init(text: "Shop")),
        image: .init(
          normal: .init(
            source: .systemSymbol(name: "bag"),
            style: .init(position: .trailing)
          )
        ),
        accessibilityLabel: "Shop"
      ),
      FKTabBarItem(
        id: "title-subtitle",
        title: .init(normal: .init(text: "Feed")),
        subtitle: .init(normal: .init(text: "For you")),
        accessibilityLabel: "Feed, For you"
      ),
      FKTabBarItem(
        id: "title-subtitle-long",
        title: .init(normal: .init(text: "Release")),
        subtitle: .init(normal: .init(text: "Beta channel preview notes")),
        accessibilityLabel: "Release, Beta channel preview notes"
      ),
      FKTabBarItem(
        id: "morph-selected",
        title: .init(
          normal: .init(text: "Image"),
          selected: .init(text: "Image tab with long text")
        ),
        image: .init(
          normal: .init(source: .systemSymbol(name: "photo")),
          selected: .init(source: .systemSymbol(name: "photo.on.rectangle.angled"))
        ),
        accessibilityLabel: "Image"
      ),
      FKTabBarItem(
        id: "disabled",
        title: .init(normal: .init(text: "Disabled")),
        image: .init(normal: .init(source: .systemSymbol(name: "lock"))),
        isEnabled: false,
        accessibilityLabel: "Disabled"
      ),
      FKTabBarItem(
        id: "custom-pill",
        title: .init(normal: .init(text: "Custom")),
        customContentIdentifier: "pill",
        accessibilityLabel: "Custom content"
      ),
      FKTabBarItem(
        id: "text-badge",
        title: .init(normal: .init(text: "Promo")),
        badge: .init(state: .init(normal: .text("NEW"))),
        accessibilityLabel: "Promo, new"
      ),
      FKTabBarItem(
        id: "accessory",
        title: .init(normal: .init(text: "Filter")),
        accessoryIcon: .systemSymbol("chevron.down"),
        accessibilityLabel: "Filter"
      ),
      FKTabBarItem(
        id: "tiny-api",
        title: .init(normal: .init(text: "API")),
        accessibilityLabel: "API"
      ),
      FKTabBarItem(
        id: "overflow-badge",
        title: .init(normal: .init(text: "Updates")),
        image: .init(normal: .init(source: .systemSymbol(name: "arrow.triangle.2.circlepath"))),
        badge: .init(state: .init(normal: .count(128))),
        accessibilityLabel: "Updates, 128"
      ),
    ]
  }

  static func makeShowcasePages(for tabs: [FKTabBarItem]) -> [UIViewController] {
    let colors: [UIColor] = [
      .systemIndigo, .systemTeal, .systemOrange, .systemPurple, .systemPink,
      .systemGreen, .systemBlue, .systemRed, .systemCyan, .systemMint,
      .systemBrown, .systemYellow, .systemGray, .systemIndigo, .systemTeal,
      .systemOrange, .systemPurple, .systemPink,
    ]
    return tabs.enumerated().map { idx, tab in
      let label = tab.accessibilityLabel ?? tab.titleText ?? tab.id
      if tab.id == "title-subtitle-long" {
        return FKPagingDemoListViewController(headerTitle: label)
      }
      return FKPagingDemoPageViewController(
        color: colors[idx % colors.count],
        titleText: label
      )
    }
  }
}

/// Custom pill tab content plus custom indicator for the navigation-bar placement demo.
@MainActor
final class FKPagingNavigationBarShowcaseCustomization: FKTabBarDefaultCustomization {
  private let contentCustomization = FKTabBarExampleContentCustomization()
  private let indicatorCustomization = FKTabBarExampleIndicatorCustomization(
    indicatorID: "paging.demo.custom",
    fillColor: .systemOrange.withAlphaComponent(0.35),
    cornerRadius: 8
  )

  override func customContentView(for item: FKTabBarItem) -> UIView? {
    contentCustomization.customContentView(for: item)
  }

  override func customIndicatorView(id: String) -> UIView? {
    indicatorCustomization.customIndicatorView(id: id)
  }
}
