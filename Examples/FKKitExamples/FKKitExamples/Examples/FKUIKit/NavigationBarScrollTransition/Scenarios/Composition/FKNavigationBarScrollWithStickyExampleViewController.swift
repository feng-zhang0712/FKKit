import FKUIKit
import UIKit

/// Same scroll view drives navigation chrome and an FKSticky strip (manual forward).
final class FKNavigationBarScrollWithStickyExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Nav + Sticky" }
  override var becomesScrollViewDelegate: Bool { true }

  private weak var navEngine: FKNavigationBarScrollEngine?
  private let stickyStrip = FKStickyExampleUI.makeStrip(
    title: "Sticky filters",
    backgroundColor: .systemTeal,
    height: 44
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Compose"

    addIntro(
      title: "Alongside FKSticky",
      body: "Both engines share one scroll view. Automatic observation is disabled; scrollViewDidScroll forwards fk_handleNavigationBarScroll and fk_handleStickyScroll. The strip is a direct stack item and pins under the navigation bar."
    )

    // Direct stack child — a wrapper's edge constraints fight FKSticky reparenting and
    // leave the strip overlapping content after a few scroll ticks.
    contentStack.addArrangedSubview(stickyStrip)
    stickyStrip.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    addFillerBlocks()

    navEngine = installDefaultEngine { engine in
      var configuration = engine.configuration
      configuration.observesAutomatically = false
      engine.configuration = configuration
    }

    var stickyConfiguration = FKStickyConfiguration.default
    stickyConfiguration.observesAutomatically = false
    scrollView.fk_stickyEngine.configuration = stickyConfiguration
    scrollView.fk_stickyEngine.stickyInsetProvider = { [weak self] in
      self?.navigationBarPinInset ?? 0
    }
    scrollView.fk_addStickyTarget(id: "filters", view: stickyStrip) { [weak self] progress in
      guard let self, let nav = self.navEngine else { return }
      self.statusLabel.text =
        FKNavigationBarScrollExampleUI.formatProgress(nav)
        + String(format: "  sticky=%@ p=%.2f", progress.state.rawValue, progress.value)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    view.layoutIfNeeded()
    scrollView.fk_reloadStickyLayout()
  }

  /// Stable distance from the scroll-view top to the bar bottom (under-nav pin line).
  ///
  /// Must **not** use `convert(_:to: scrollView)` — UIScrollView’s coordinate system includes
  /// `contentOffset`, so the pin line would travel with scrolling and the stuck strip would
  /// appear to drift across the page.
  private var navigationBarPinInset: CGFloat {
    max(view.safeAreaInsets.top, 0)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollView.fk_handleNavigationBarScroll()
    scrollView.fk_handleStickyScroll()
  }
}
