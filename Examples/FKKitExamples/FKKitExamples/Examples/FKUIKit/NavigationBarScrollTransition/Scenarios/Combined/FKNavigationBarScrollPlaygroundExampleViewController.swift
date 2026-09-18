import FKUIKit
import UIKit

/// Live toggles across configuration, endpoints, and observation.
final class FKNavigationBarScrollPlaygroundExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Playground" }
  private weak var engine: FKNavigationBarScrollEngine?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"

    addIntro(
      title: "Interactive playground",
      body: "Toggle application target, observation, status updates, progress epsilon, and swap endpoint factories while scrolling."
    )
    addActions([
      FKNavigationBarScrollExampleUI.makeButton("Cycle apply target item/bar/both") { [weak self] in
        self?.mutate { configuration in
          switch configuration.applicationTarget {
          case .navigationItem: configuration.applicationTarget = .navigationBar
          case .navigationBar: configuration.applicationTarget = .both
          case .both: configuration.applicationTarget = .navigationItem
          }
        }
      },
      FKNavigationBarScrollExampleUI.makeButton("Toggle auto observation") { [weak self] in
        self?.mutate { $0.observesAutomatically.toggle() }
      },
      FKNavigationBarScrollExampleUI.makeButton("Toggle auto apply") { [weak self] in
        self?.mutate { $0.appliesAppearanceAutomatically.toggle() }
      },
      FKNavigationBarScrollExampleUI.makeButton("Toggle updatesStatusBar") { [weak self] in
        self?.mutate { $0.updatesStatusBarAppearance.toggle() }
      },
      FKNavigationBarScrollExampleUI.makeButton("Epsilon 0.001 ↔ 0.08") { [weak self] in
        self?.mutate { configuration in
          configuration.progressEpsilon = configuration.progressEpsilon > 0.04 ? 0.001 : 0.08
        }
      },
      FKNavigationBarScrollExampleUI.makeButton("Swap transparent/solid endpoints") { [weak self] in
        guard let self, let engine = self.engine else { return }
        let from = engine.fromAppearance
        engine.fromAppearance = engine.toAppearance
        engine.toAppearance = from
        engine.reload()
        self.cachedStatusBarStyle = engine.resolvedStatusBarStyle
        self.setNeedsStatusBarAppearanceUpdate()
        self.updateStatus(from: engine)
      },
      FKNavigationBarScrollExampleUI.makeButton("endOffset hero ↔ 140") { [weak self] in
        guard let self else { return }
        self.mutate { configuration in
          configuration.endOffset = abs(configuration.endOffset - self.heroHeight) < 1 ? 140 : self.heroHeight
        }
      },
    ])
    addFillerBlocks()

    engine = installDefaultEngine()
  }

  private func mutate(_ body: (inout FKNavigationBarScrollConfiguration) -> Void) {
    guard let engine else { return }
    var configuration = engine.configuration
    body(&configuration)
    engine.configuration = configuration
    if configuration.observesAutomatically {
      engine.startObserving()
    }
    engine.reload()
    cachedStatusBarStyle = engine.resolvedStatusBarStyle
    setNeedsStatusBarAppearanceUpdate()
    updateStatus(from: engine)
  }
}
