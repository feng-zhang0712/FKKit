import FKUIKit
import UIKit

/// Manual scroll forwarding when automatic KVO is disabled.
final class FKNavigationBarScrollManualObservationExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Manual Drive" }
  override var becomesScrollViewDelegate: Bool { true }

  private weak var engine: FKNavigationBarScrollEngine?
  private var forwardsScroll = true

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Manual"

    addIntro(
      title: "Manual observation",
      body: "observesAutomatically = false. Scroll ticks are forwarded via fk_handleNavigationBarScroll / handleScroll only while forwarding is enabled. Also demos startObserving / stopObserving."
    )
    addActions([
      FKNavigationBarScrollExampleUI.makeButton("Toggle scroll forwarding") { [weak self] in
        guard let self else { return }
        self.forwardsScroll.toggle()
        self.statusLabel.text = "forwarding=\(self.forwardsScroll)  " + (self.statusLabel.text ?? "")
      },
      FKNavigationBarScrollExampleUI.makeButton("Call handleScroll() once") { [weak self] in
        self?.engine?.handleScroll()
      },
      FKNavigationBarScrollExampleUI.makeButton("fk_handleNavigationBarScroll()") { [weak self] in
        self?.scrollView.fk_handleNavigationBarScroll()
      },
      FKNavigationBarScrollExampleUI.makeButton("Enable auto KVO (startObserving)") { [weak self] in
        guard let self, let engine = self.engine else { return }
        var configuration = engine.configuration
        configuration.observesAutomatically = true
        engine.configuration = configuration
        engine.startObserving()
      },
      FKNavigationBarScrollExampleUI.makeButton("stopObserving()") { [weak self] in
        self?.engine?.stopObserving()
      },
    ])
    addFillerBlocks()

    engine = installDefaultEngine { engine in
      var configuration = engine.configuration
      configuration.observesAutomatically = false
      engine.configuration = configuration
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard forwardsScroll else { return }
    scrollView.fk_handleNavigationBarScroll()
  }
}
