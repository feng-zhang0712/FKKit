import FKCoreKit
import UIKit

/// Demonstrates ``FKPluggableServices/productionDefaults()`` composition-root wiring.
@MainActor
final class FKPluggableCompositionRootExampleViewController: FKPluggableExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Composition Root"

    addActionButton("1) FKPluggableServices.productionDefaults()") { [weak self] in
      let services = FKPluggableServices.productionDefaults()
      self?.appendOutput("apiClient: \(type(of: services.apiClient))")
      self?.appendOutput("storage: \(type(of: services.storage))")
      self?.appendOutput("session: \(type(of: services.session))")
      self?.appendOutput("environment: \(services.environment.environment.rawValue)")
      self?.appendOutput("logger: \(type(of: services.logger))")
      self?.appendOutput("reachability.isReachable = \(services.reachability.isReachable)")
    }
    addActionButton("2) Sign in via production session store") { [weak self] in
      let services = FKPluggableServices.productionDefaults()
      guard let store = services.session as? FKUserSessionStore else {
        self?.appendOutput("Session is not FKUserSessionStore")
        return
      }
      try? store.signIn(userID: "demo-\(Int.random(in: 1000...9999))")
      self?.appendOutput("authenticated=\(services.session.isAuthenticated), userID=\(services.session.userID ?? "nil")")
    }
    addActionButton("3) FKMockAPIClient canned response") { [weak self] in
      Task { await self?.runMockAPIClient() }
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func runMockAPIClient() async {
    let mock = FKMockAPIClient()
    let url = URL(string: "https://api.example.com/v1/profile")!
    mock.setResponse(
      .success(FKAPIResponse(data: Data("{\"name\":\"Demo\"}".utf8), httpResponse: nil)),
      forURL: url
    )
    let request = FKAPIRequest(url: url, method: .get, body: nil)
    do {
      let response = try await mock.perform(request)
      appendOutput("Mock API bytes: \(response.data.count)")
    } catch {
      appendOutput("Mock API error: \(error.localizedDescription)")
    }
  }
}
