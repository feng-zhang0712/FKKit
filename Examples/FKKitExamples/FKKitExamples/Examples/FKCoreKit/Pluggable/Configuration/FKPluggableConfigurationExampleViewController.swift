import FKCoreKit
import UIKit

/// Demonstrates `FKAppEnvironmentProviding`, `FKFeatureFlagProviding`, and `FKRemoteConfigProviding`
/// using library reference implementations.
final class FKPluggableConfigurationExampleViewController: FKPluggableExampleBaseViewController {

  private var environment: any FKAppEnvironmentProviding = FKBuildTimeAppEnvironment(
    environment: .development,
    apiBaseURL: URL(string: "https://dev-api.example.com")!,
    webBaseURL: URL(string: "https://dev.example.com")
  )
  private let featureFlags = FKInMemoryFeatureFlags(
    defaults: ["new_checkout": true, "beta_player": false],
    stringDefaults: ["home_banner": "spring_sale"]
  )
  private let remoteConfig = FKJSONRemoteConfigProvider(
    configuration: FKJSONRemoteConfigConfiguration(
      bundleResourceName: "remote_config_default",
      cacheDirectoryName: nil
    )
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Configuration"

    addActionButton("1) FKBuildTimeAppEnvironment (dev)") { [weak self] in
      self?.logEnvironment()
    }
    addActionButton("2) Switch to staging environment") { [weak self] in
      self?.environment = FKBuildTimeAppEnvironment(
        environment: .staging,
        apiBaseURL: URL(string: "https://staging-api.example.com")!,
        webBaseURL: URL(string: "https://staging.example.com")
      )
      self?.logEnvironment()
    }
    addActionButton("3) Switch to production environment") { [weak self] in
      self?.environment = FKBuildTimeAppEnvironment(
        environment: .production,
        apiBaseURL: URL(string: "https://api.example.com")!,
        webBaseURL: nil
      )
      self?.logEnvironment()
    }
    addActionButton("4) FKInMemoryFeatureFlags.isEnabled") { [weak self] in
      guard let self else { return }
      appendOutput("new_checkout = \(featureFlags.isEnabled("new_checkout"))")
      appendOutput("beta_player = \(featureFlags.isEnabled("beta_player"))")
      appendOutput("unknown_flag = \(featureFlags.isEnabled("unknown_flag"))")
    }
    addActionButton("5) Toggle new_checkout flag") { [weak self] in
      guard let self else { return }
      let next = !featureFlags.isEnabled("new_checkout")
      featureFlags.setEnabled(next, forKey: "new_checkout")
      appendOutput("new_checkout toggled → \(next)")
    }
    addActionButton("6) FKJSONRemoteConfigProvider bundled defaults") { [weak self] in
      self?.appendOutput("support_email = \(self?.remoteConfig.string(forKey: "support_email") ?? "nil")")
      self?.appendOutput("welcome_message = \(self?.remoteConfig.string(forKey: "welcome_message") ?? "nil")")
    }
    addActionButton("7) FKRemoteConfigProviding.fetch (missing URL → error)") { [weak self] in
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
      appendOutput("fetch() OK (unexpected without remoteURL)")
    } catch {
      appendOutput("fetch error: \(error)")
    }
  }
}
