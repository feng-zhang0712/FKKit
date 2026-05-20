import FKCoreKit
import UIKit

/// Demonstrates `FKPluggable.contractVersion`, `FKPluggableObservationToken`, and `FKAppLifecycleObserving`.
@MainActor
final class FKPluggableCoreExampleViewController: FKPluggableExampleBaseViewController {

  private let lifecycle = DemoLifecycleObserver()
  private var lifecycleToken: FKPluggableObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Core"
    appendOutput("FKPluggable.contractVersion = \(FKPluggable.contractVersion)")

    lifecycleToken = lifecycle.observe { [weak self] state in
      Task { @MainActor in
        self?.appendOutput("Lifecycle observer fired: \(state.rawValue)")
      }
    }

    addActionButton("Simulate background") { [weak self] in
      self?.lifecycle.simulate(.background)
    }
    addActionButton("Simulate active") { [weak self] in
      self?.lifecycle.simulate(.active)
    }
    addActionButton("Read current lifecycle state") { [weak self] in
      guard let self else { return }
      appendOutput("Current state: \(lifecycle.state.rawValue)")
    }
    addActionButton("Cancel lifecycle observation token") { [weak self] in
      self?.lifecycleToken?.cancel()
      self?.lifecycleToken = nil
      self?.appendOutput("Lifecycle token cancelled (no more callbacks).")
    }
    addActionButton("Demo one-shot observation token") { [weak self] in
      let token = FKPluggableObservationToken {
        Task { @MainActor in
          self?.appendOutput("Token cleanup ran.")
        }
      }
      token.cancel()
      self?.appendOutput("Called cancel() on a standalone token.")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      lifecycleToken?.cancel()
      lifecycleToken = nil
    }
  }
}
