import FKUIKit
import UIKit

/// Demonstrates startOffset / endOffset range mapping.
final class FKNavigationBarScrollOffsetRangeExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Offset Range" }
  private weak var engine: FKNavigationBarScrollEngine?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Range"

    addIntro(
      title: "startOffset / endOffset",
      body: "Progress maps linearly between startOffset and endOffset. Toggle ranges to see when the bar finishes transitioning relative to the hero."
    )
    addActions([
      FKNavigationBarScrollExampleUI.makeButton("Range 0…hero") { [weak self] in
        self?.applyRange(start: 0, end: self?.heroHeight ?? 220)
      },
      FKNavigationBarScrollExampleUI.makeButton("Range 40…hero") { [weak self] in
        self?.applyRange(start: 40, end: self?.heroHeight ?? 220)
      },
      FKNavigationBarScrollExampleUI.makeButton("Range 0…120 (short)") { [weak self] in
        self?.applyRange(start: 0, end: 120)
      },
      FKNavigationBarScrollExampleUI.makeButton("Invalid span (end ≤ start)") { [weak self] in
        self?.applyRange(start: 100, end: 80)
      },
    ])
    addFillerBlocks()

    engine = installDefaultEngine()
  }

  private func applyRange(start: CGFloat, end: CGFloat) {
    guard let engine else { return }
    var configuration = engine.configuration
    configuration.startOffset = start
    configuration.endOffset = end
    engine.configuration = configuration
    engine.reload()
    updateStatus(from: engine)
  }
}
