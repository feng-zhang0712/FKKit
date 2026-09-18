import FKUIKit
import UIKit

/// Runtime enable / force / reload / reset controls and scroll-view helpers.
final class FKNavigationBarScrollRuntimeControlsExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Controls" }
  private weak var engine: FKNavigationBarScrollEngine?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Controls"

    addIntro(
      title: "Runtime controls",
      body: "isEnabled, forceProgress / clearForcedProgress, reload / fk_reloadNavigationBarScroll, reset / fk_resetNavigationBarScroll, and bind(scrollView:viewController:)."
    )
    addActions([
      FKNavigationBarScrollExampleUI.makeButton("Toggle isEnabled") { [weak self] in
        guard let self, let engine = self.engine else { return }
        var configuration = engine.configuration
        configuration.isEnabled.toggle()
        engine.configuration = configuration
        self.updateStatus(from: engine)
      },
      FKNavigationBarScrollExampleUI.makeButton("Force progress = 0") { [weak self] in
        self?.engine?.forceProgress(0)
        if let engine = self?.engine { self?.updateStatus(from: engine) }
      },
      FKNavigationBarScrollExampleUI.makeButton("Force progress = 0.5") { [weak self] in
        self?.engine?.forceProgress(0.5)
        if let engine = self?.engine {
          self?.cachedStatusBarStyle = engine.resolvedStatusBarStyle
          self?.setNeedsStatusBarAppearanceUpdate()
          self?.updateStatus(from: engine)
        }
      },
      FKNavigationBarScrollExampleUI.makeButton("Force progress = 1") { [weak self] in
        self?.engine?.forceProgress(1)
        if let engine = self?.engine {
          self?.cachedStatusBarStyle = engine.resolvedStatusBarStyle
          self?.setNeedsStatusBarAppearanceUpdate()
          self?.updateStatus(from: engine)
        }
      },
      FKNavigationBarScrollExampleUI.makeButton("clearForcedProgress()") { [weak self] in
        self?.engine?.clearForcedProgress()
        if let engine = self?.engine { self?.updateStatus(from: engine) }
      },
      FKNavigationBarScrollExampleUI.makeButton("reload() / fk_reload…") { [weak self] in
        self?.scrollView.fk_reloadNavigationBarScroll()
        if let engine = self?.engine { self?.updateStatus(from: engine) }
      },
      FKNavigationBarScrollExampleUI.makeButton("reset(stopObserving: false)") { [weak self] in
        self?.scrollView.fk_resetNavigationBarScroll(stopObserving: false)
        if let engine = self?.engine {
          self?.cachedStatusBarStyle = engine.resolvedStatusBarStyle
          self?.setNeedsStatusBarAppearanceUpdate()
          self?.updateStatus(from: engine)
        }
      },
      FKNavigationBarScrollExampleUI.makeButton("Re-bind scroll + VC") { [weak self] in
        guard let self, let engine = self.engine else { return }
        engine.bind(scrollView: self.scrollView, viewController: self)
        engine.reload()
        self.updateStatus(from: engine)
      },
    ])
    addFillerBlocks()

    engine = installDefaultEngine()
  }
}
