import FKCoreKit
import UIKit

/// Demonstrates `FKAppEnvironmentProviding`, `FKFeatureFlagProviding`, and `FKRemoteConfigProviding`.
final class FKPluggableConfigurationExampleViewController: FKPluggableExampleBaseViewController {

  private var environment = DemoAppEnvironment(
    environment: .development,
    apiBaseURL: URL(string: "https://dev-api.example.com")!,
    webBaseURL: URL(string: "https://dev.example.com")
  )
  private var featureFlags = DemoFeatureFlags()
  private let remoteConfig = DemoRemoteConfig()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Configuration"

    addActionButton("1) FKAppEnvironmentProviding (dev)") { [weak self] in
      self?.logEnvironment()
    }
    addActionButton("2) Switch to staging environment") { [weak self] in
      self?.environment = DemoAppEnvironment(
        environment: .staging,
        apiBaseURL: URL(string: "https://staging-api.example.com")!,
        webBaseURL: URL(string: "https://staging.example.com")
      )
      self?.logEnvironment()
    }
    addActionButton("3) Switch to production environment") { [weak self] in
      self?.environment = DemoAppEnvironment(
        environment: .production,
        apiBaseURL: URL(string: "https://api.example.com")!,
        webBaseURL: nil
      )
      self?.logEnvironment()
    }
    addActionButton("4) FKFeatureFlagProviding.isEnabled") { [weak self] in
      guard let self else { return }
      appendOutput("new_checkout = \(featureFlags.isEnabled("new_checkout"))")
      appendOutput("beta_player = \(featureFlags.isEnabled("beta_player"))")
      appendOutput("unknown_flag = \(featureFlags.isEnabled("unknown_flag"))")
    }
    addActionButton("5) FKFeatureFlagProviding.stringValue") { [weak self] in
      let banner = self?.featureFlags.stringValue(for: "home_banner") ?? "(nil)"
      self?.appendOutput("home_banner payload: \(banner)")
    }
    addActionButton("6) FKRemoteConfigProviding.fetch + read") { [weak self] in
      Task { await self?.fetchRemoteConfig() }
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func logEnvironment() {
    appendOutput("environment=\(environment.environment.rawValue), debuggable=\(environment.environment.isDebuggable)")
    appendOutput("apiBaseURL=\(environment.apiBaseURL.absoluteString)")
    appendOutput("webBaseURL=\(environment.webBaseURL?.absoluteString ?? "nil")")
  }

  private func fetchRemoteConfig() async {
    do {
      try await remoteConfig.fetch()
      appendOutput("fetch() OK")
      appendOutput("support_email = \(remoteConfig.string(forKey: "support_email") ?? "nil")")
      appendOutput("force_update = \(String(describing: remoteConfig.bool(forKey: "force_update")))")
      appendOutput("fetched_at = \(remoteConfig.string(forKey: "fetched_at") ?? "nil")")
    } catch {
      appendOutput("fetch error: \(error.localizedDescription)")
    }
  }
}
