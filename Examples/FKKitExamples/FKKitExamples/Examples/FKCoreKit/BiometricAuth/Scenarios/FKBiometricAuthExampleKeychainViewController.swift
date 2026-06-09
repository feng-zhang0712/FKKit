import FKCoreKit
import UIKit

/// Pattern A from README: authenticate, then read ``FKKeychainStorage`` (no SecAccessControl).
final class FKBiometricAuthExampleKeychainViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuthExampleSupport.liveAuth
  private let storage = FKBiometricAuthExampleSupport.keychainStorage()
  private let secretKey = "wallet_refresh_token"

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Keychain Unlock"

    addSimulatorFaceIDGuide()
    addInfoLabel(
      "1) Store a demo token in Keychain (no biometric AccessControl). 2) Authenticate. 3) Read token only after success — app-layer gate (Pattern A)."
    )

    addActionButton("Seed demo token in Keychain") { [weak self] in
      self?.seedToken()
    }

    addActionButton("Unlock & read token (authenticate → value)") { [weak self] in
      self?.unlockAndRead()
    }

    addActionButton("Read without auth (always succeeds if seeded)") { [weak self] in
      self?.readWithoutGate()
    }

    addActionButton("Remove demo token") { [weak self] in
      self?.removeToken()
    }

    addSimulatorRecoverySection(auth: auth)

    addClearLogButton()
  }

  private func seedToken() {
    do {
      let token = FKBiometricExampleKeychainToken(
        value: "demo_refresh_\(Int(Date().timeIntervalSince1970))",
        issuedAt: Date().timeIntervalSince1970
      )
      try storage.set(token, key: secretKey, ttl: nil)
      appendLog("Seeded Keychain token under key '\(secretKey)'")
    } catch {
      appendLog("Seed failed: \(error.localizedDescription)")
    }
  }

  private func unlockAndRead() {
    runAuthTask("keychain.unlock") { [weak self] in
      guard let self else { return }
      try await auth.authenticate(reason: FKBiometricReason.unlockApp())
      let token: FKBiometricExampleKeychainToken = try storage.value(key: secretKey, as: FKBiometricExampleKeychainToken.self)
      appendLog("Authenticated — token.value: \(token.value.prefix(12))… (full value not logged)")
    }
  }

  private func readWithoutGate() {
    do {
      let token: FKBiometricExampleKeychainToken = try storage.value(key: secretKey, as: FKBiometricExampleKeychainToken.self)
      appendLog("[no gate] read token.value: \(token.value.prefix(12))…")
    } catch {
      appendLog("[no gate] read failed: \(error.localizedDescription)")
    }
  }

  private func removeToken() {
    do {
      try storage.remove(key: secretKey)
      appendLog("Removed Keychain key '\(secretKey)'")
    } catch {
      appendLog("Remove failed: \(error.localizedDescription)")
    }
  }
}
