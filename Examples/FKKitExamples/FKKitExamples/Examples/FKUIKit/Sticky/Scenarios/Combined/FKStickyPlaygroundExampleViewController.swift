import FKUIKit
import UIKit

/// Live toggles covering the major configuration surface in one screen.
final class FKStickyPlaygroundExampleViewController: FKStickyExampleScrollPageViewController {
  private let stripA = FKStickyExampleUI.makeStrip(title: "Play A", backgroundColor: .systemBlue)
  private let stripB = FKStickyExampleUI.makeStrip(title: "Play B", backgroundColor: .systemPurple)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"
    addIntro(
      title: "Interactive playground",
      body: "Toggle edge, collision, shadow, hysteresis, inset, and automatic observation while scrolling."
    )

    contentStack.addArrangedSubview(stripA)
    addFillerBlocks(count: 6)
    contentStack.addArrangedSubview(stripB)
    addFillerBlocks(count: 14)

    let engine = scrollView.fk_stickyEngine
    engine.addTarget(id: "a", view: stripA)
    engine.addTarget(id: "b", view: stripB)
    engine.onStuckTargetsChange = { [weak self] ids in
      self?.updateStatus("stuck=\(ids) edge=\(engine.configuration.edge.rawValue) collision=\(engine.configuration.collisionBehavior.rawValue)")
    }

    addActions([
      FKStickyExampleUI.makeButton("Toggle edge top/bottom") { [weak self] in
        self?.mutate { config in
          config.edge = config.edge == .top ? .bottom : .top
        }
      },
      FKStickyExampleUI.makeButton("Toggle collision pushOff/stack") { [weak self] in
        self?.mutate { config in
          config.collisionBehavior = config.collisionBehavior == .pushOff ? .stack : .pushOff
        }
      },
      FKStickyExampleUI.makeButton("Toggle appliesStuckShadow") { [weak self] in
        self?.mutate { $0.appliesStuckShadow.toggle() }
      },
      FKStickyExampleUI.makeButton("Cycle stickyInset 0/20/40") { [weak self] in
        self?.mutate { config in
          let next: CGFloat
          switch config.stickyInset {
          case ..<10: next = 20
          case ..<30: next = 40
          default: next = 0
          }
          config.stickyInset = next
        }
      },
      FKStickyExampleUI.makeButton("Toggle hysteresis 0/16") { [weak self] in
        self?.mutate { config in
          config.unstickHysteresis = config.unstickHysteresis < 1 ? 16 : 0
        }
      },
      FKStickyExampleUI.makeButton("Toggle auto observation") { [weak self] in
        guard let self else { return }
        let engine = self.scrollView.fk_stickyEngine
        if engine.configuration.observesAutomatically {
          engine.stopObserving()
        } else {
          engine.startObserving()
        }
        self.updateStatus("observesAutomatically=\(engine.configuration.observesAutomatically)")
      },
    ])
  }

  private func mutate(_ body: (inout FKStickyConfiguration) -> Void) {
    var configuration = scrollView.fk_stickyEngine.configuration
    body(&configuration)
    scrollView.fk_stickyEngine.configuration = configuration
    scrollView.fk_reloadStickyLayout()
    updateStatus(
      "edge=\(configuration.edge.rawValue) collision=\(configuration.collisionBehavior.rawValue) inset=\(Int(configuration.stickyInset)) shadow=\(configuration.appliesStuckShadow) hyst=\(Int(configuration.unstickHysteresis))"
    )
  }
}
