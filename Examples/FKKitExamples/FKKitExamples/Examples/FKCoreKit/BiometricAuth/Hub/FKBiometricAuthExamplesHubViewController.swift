import UIKit

/// Grouped index of ``FKBiometricAuth`` examples under `FKCoreKit/Components/BiometricAuth`.
final class FKBiometricAuthExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Inspection & readiness",
      rows: [
        Row(
          title: "Capability inspection",
          subtitle: "Silent probe — biometryType, enrollment, passcode, per-policy canEvaluatePolicy (no UI)",
          make: { FKBiometricAuthExampleCapabilityViewController() }
        ),
        Row(
          title: "Not enrolled guidance",
          subtitle: "When capability.canAuthenticate is false — host UX and Settings path",
          make: { FKBiometricAuthExampleNotEnrolledViewController() }
        ),
      ]
    ),
    Section(
      title: "Live authentication",
      rows: [
        Row(
          title: "Authentication basics",
          subtitle: "async success, user cancel, authenticateIfAvailable, closure API, invalid reason",
          make: { FKBiometricAuthExampleAuthenticationViewController() }
        ),
        Row(
          title: "Policy comparison",
          subtitle: "biometricsOnly vs biometricsOrPasscode vs devicePasscode, allowPasscodeFallback",
          make: { FKBiometricAuthExamplePolicyViewController() }
        ),
      ]
    ),
    Section(
      title: "Configuration",
      rows: [
        Row(
          title: "Localized reasons & options",
          subtitle: "FKBiometricReason, fallback title, custom FKBiometricAuthConfiguration",
          make: { FKBiometricAuthExampleConfigurationViewController() }
        ),
        Row(
          title: "Reuse duration",
          subtitle: "touchIDAuthenticationAllowableReuseDuration — back-to-back authenticate within window",
          make: { FKBiometricAuthExampleReuseDurationViewController() }
        ),
      ]
    ),
    Section(
      title: "Cancellation & lifecycle",
      rows: [
        Row(
          title: "Cancel in flight",
          subtitle: "cancelAuthentication() while system UI is visible → appCancelled",
          make: { FKBiometricAuthExampleCancelInFlightViewController() }
        ),
        Row(
          title: "Swift Task cancellation",
          subtitle: "Simulates SwiftUI .task teardown — invalidates LAContext via withTaskCancellationHandler",
          make: { FKBiometricAuthExampleTaskCancellationViewController() }
        ),
      ]
    ),
    Section(
      title: "Testing & integration",
      rows: [
        Row(
          title: "Mock & error catalog",
          subtitle: "FKMockBiometricAuthenticator lockout/cancel, all FKBiometricError LocalizedError strings",
          make: { FKBiometricAuthExampleMockViewController() }
        ),
        Row(
          title: "Keychain unlock pattern",
          subtitle: "App-layer gate: authenticate → FKKeychainStorage.value (Pattern A from README)",
          make: { FKBiometricAuthExampleKeychainViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBiometricAuth"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
