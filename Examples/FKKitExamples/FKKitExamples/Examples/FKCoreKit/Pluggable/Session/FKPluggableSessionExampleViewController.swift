import FKCoreKit
import UIKit

/// Demonstrates `FKUserSessionProviding` and `FKUserSessionObserving`.
@MainActor
final class FKPluggableSessionExampleViewController: FKPluggableExampleBaseViewController {

  private let session = DemoUserSession()
  private var observationToken: FKPluggableObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Session"

    observationToken = session.observeAuthenticationChange { [weak self] isAuthenticated in
      Task { @MainActor in
        self?.appendOutput("Auth observer: isAuthenticated=\(isAuthenticated)")
      }
    }

    addActionButton("1) signIn(userID:) via demo session") { [weak self] in
      self?.session.signIn(userID: "user-\(Int.random(in: 1000...9999))")
      self?.logSession()
    }
    addActionButton("2) signOut() — FKUserSessionProviding") { [weak self] in
      try? self?.session.signOut()
      self?.logSession()
    }
    addActionButton("3) Read isAuthenticated + userID") { [weak self] in
      self?.logSession()
    }
    addActionButton("4) Cancel auth observation token") { [weak self] in
      self?.observationToken?.cancel()
      self?.observationToken = nil
      self?.appendOutput("Auth observer removed.")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func logSession() {
    appendOutput("Session → authenticated=\(session.isAuthenticated), userID=\(session.userID ?? "nil")")
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      observationToken?.cancel()
      observationToken = nil
    }
  }
}
