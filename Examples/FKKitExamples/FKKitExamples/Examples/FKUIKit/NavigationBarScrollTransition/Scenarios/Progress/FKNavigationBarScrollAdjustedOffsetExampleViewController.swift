import FKUIKit
import UIKit

/// Demonstrates usesAdjustedContentOffset with a simulated top inset.
final class FKNavigationBarScrollAdjustedOffsetExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Adjusted Offset" }
  private weak var engine: FKNavigationBarScrollEngine?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Adjusted"

    addIntro(
      title: "usesAdjustedContentOffset",
      body: "When true, progress uses contentOffset.y + adjustedContentInset.top. Toggle the flag and a simulated top inset (like a refresh control) to compare mapping."
    )
    addActions([
      FKNavigationBarScrollExampleUI.makeButton("Toggle usesAdjustedContentOffset") { [weak self] in
        guard let self, let engine = self.engine else { return }
        var configuration = engine.configuration
        configuration.usesAdjustedContentOffset.toggle()
        engine.configuration = configuration
        engine.reload()
        self.updateStatus(from: engine)
      },
      FKNavigationBarScrollExampleUI.makeButton("Inset top 0 ↔ 64") { [weak self] in
        guard let self else { return }
        let next: CGFloat = abs(self.scrollView.contentInset.top - 64) < 0.5 ? 0 : 64
        self.scrollView.contentInset.top = next
        // Keep content visually aligned when inset changes.
        self.scrollView.contentOffset = CGPoint(x: 0, y: -next)
        self.engine?.reload()
        if let engine = self.engine {
          self.updateStatus(from: engine)
        }
      },
    ])
    addFillerBlocks()

    engine = installDefaultEngine { engine in
      var configuration = engine.configuration
      configuration.usesAdjustedContentOffset = true
      engine.configuration = configuration
    }
  }
}
