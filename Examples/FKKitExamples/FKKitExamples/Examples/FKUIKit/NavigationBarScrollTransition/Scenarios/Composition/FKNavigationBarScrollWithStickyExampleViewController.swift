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
      body: "Both engines share one scroll view. Automatic observation is disabled; scrollViewDidScroll forwards fk_handleNavigationBarScroll and fk_handleStickyScroll."
    )

    stickyStrip.translatesAutoresizingMaskIntoConstraints = false
    let stripWrap = UIView()
    stripWrap.translatesAutoresizingMaskIntoConstraints = false
    stripWrap.addSubview(stickyStrip)
    NSLayoutConstraint.activate([
      stickyStrip.topAnchor.constraint(equalTo: stripWrap.topAnchor, constant: 8),
      stickyStrip.bottomAnchor.constraint(equalTo: stripWrap.bottomAnchor, constant: -8),
      stickyStrip.leadingAnchor.constraint(equalTo: stripWrap.leadingAnchor, constant: 16),
      stickyStrip.trailingAnchor.constraint(equalTo: stripWrap.trailingAnchor, constant: -16),
      stickyStrip.heightAnchor.constraint(equalToConstant: 44),
    ])
    contentStack.addArrangedSubview(stripWrap)
    addFillerBlocks()

    navEngine = installDefaultEngine { engine in
      var configuration = engine.configuration
      configuration.observesAutomatically = false
      engine.configuration = configuration
    }

    var stickyConfiguration = FKStickyConfiguration.default
    stickyConfiguration.observesAutomatically = false
    stickyConfiguration.stickyInset = 0
    scrollView.fk_stickyEngine.configuration = stickyConfiguration
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

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollView.fk_handleNavigationBarScroll()
    scrollView.fk_handleStickyScroll()
  }
}
