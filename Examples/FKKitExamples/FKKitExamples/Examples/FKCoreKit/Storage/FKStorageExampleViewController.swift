//
//  FKStorageExampleViewController.swift
//  FKKitExamples
//
//  Interactive catalog of FKStorage backends and APIs. All UI copy is English-only.
//

import FKCoreKit
import UIKit

/// Demonstrates every public surface area: synchronous CRUD, `exists`, `remove(key:)`, `allKeys()`,
/// TTL + `purgeExpired()`, `removeAll()`, and the async facades in `StorageAsync.swift`.
final class FKStorageExampleViewController: UIViewController {
  // MARK: - Backends (one instance per scope; each backend serializes internally)

  /// Only keys under `keyPrefix` participate in `removeAll()` / `allKeys()`.
  private let userDefaultsStorage = FKUserDefaultsStorage(keyPrefix: "fk.examples.storage.")

  private lazy var keychainStorage: FKKeychainStorage = {
    let id = Bundle.main.bundleIdentifier ?? "FKKitExamples"
    return FKKeychainStorage(service: "\(id).fkstorage.example")
  }()

  private let fileStorage: FKFileStorage
  private let memoryStorage = FKMemoryStorage()

  // MARK: - UI (same layout contract as `FKPermissionsExampleViewController`)

  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let logView = UITextView()

  init() {
    do {
      fileStorage = try FKFileStorage(directoryName: "FKStorageExamples")
    } catch {
      fatalError("FKFileStorage init failed: \(error)")
    }
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKStorage"
    view.backgroundColor = .systemBackground
    buildLayout()
    buildSections()
    appendLog("FKStorage playground ready. Sections mirror real integration order: sync APIs, TTL, async facades, bulk purge, then scoped wipe.")
    appendLog("Tip: run TTL samples, then tap \"Purge expired (all backends)\" or wait for expiry and read again.")
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 8

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func buildSections() {
    addSectionHeading("UserDefaults — synchronous set / value")
    addActionButton("Increment launch count (Int)") { [weak self] in self?.udIncrementLaunchCount() }
    addActionButton("Read launch count") { [weak self] in self?.udReadLaunchCount() }
    addActionButton("Set prefersDarkMode = true (Bool)") { [weak self] in self?.udSetDarkMode() }
    addActionButton("Read prefersDarkMode") { [weak self] in self?.udReadDarkMode() }
    addActionButton("List logical keys (allKeys)") { [weak self] in self?.udListKeys() }

    addSectionHeading("UserDefaults — exists(key) + remove(key)")
    addActionButton("exists(key) for launch count") { [weak self] in self?.udExistsLaunchCount() }
    addActionButton("remove(key) prefersDarkMode (single key)") { [weak self] in self?.udRemoveDarkModeKey() }

    addSectionHeading("UserDefaults — TTL (seconds) + purgeExpired")
    addActionButton("set String with 8s TTL (userDefaultsTTLSample)") { [weak self] in self?.udSetTTLString() }
    addActionButton("value before expiry") { [weak self] in self?.udReadTTLString() }
    addActionButton("purgeExpired() for UserDefaults only") { [weak self] in self?.udPurgeExpiredOnly() }

    addSectionHeading("Keychain — Codable payloads")
    addActionButton("set access token (FKStorageExampleAuthToken)") { [weak self] in self?.kcSaveToken() }
    addActionButton("set password payload (FKStorageExamplePassword)") { [weak self] in self?.kcSavePassword() }
    addActionButton("value both secrets") { [weak self] in self?.kcReadSecrets() }
    addActionButton("remove(key) access token only") { [weak self] in self?.kcRemoveToken() }

    addSectionHeading("Keychain — exists + allKeys + TTL")
    addActionButton("exists(key) access token") { [weak self] in self?.kcExistsToken() }
    addActionButton("allKeys() for this service") { [weak self] in self?.kcListKeys() }
    addActionButton("set token with 5s TTL (keychainTTLSample)") { [weak self] in self?.kcSetShortTTLToken() }
    addActionButton("read keychain TTL sample (fails after expiry)") { [weak self] in self?.kcReadShortTTLToken() }

    addSectionHeading("File storage — Codable, Data, String")
    addActionButton("set user profile (Codable JSON)") { [weak self] in self?.fileSaveProfile() }
    addActionButton("value user profile") { [weak self] in self?.fileLoadProfile() }
    addActionButton("set PNG Data (binary blob)") { [weak self] in self?.fileSaveImage() }
    addActionButton("value Data") { [weak self] in self?.fileLoadImage() }
    addActionButton("set plain String note") { [weak self] in self?.fileSaveText() }
    addActionButton("set JSON document struct") { [weak self] in self?.fileSaveJSON() }
    addActionButton("print directoryURL (disk location)") { [weak self] in self?.fileShowDirectory() }

    addSectionHeading("File storage — exists + remove(key) + allKeys + TTL")
    addActionButton("exists(key) user profile") { [weak self] in self?.fileExistsProfile() }
    addActionButton("remove(key) text note only") { [weak self] in self?.fileRemoveTextNote() }
    addActionButton("allKeys() on disk index") { [weak self] in self?.fileListKeys() }
    addActionButton("set document with 6s TTL (fileTTLSample)") { [weak self] in self?.fileSetTTLDocument() }
    addActionButton("read file TTL sample") { [weak self] in self?.fileReadTTLDocument() }

    addSectionHeading("Memory — TTL + eviction")
    addActionButton("set String, TTL = 2s") { [weak self] in self?.memSetTTL() }
    addActionButton("value immediately") { [weak self] in self?.memReadTTL() }
    addActionButton("sleep 3s, then value (expect notFound)") { [weak self] in self?.memReadAfterDelay() }

    addSectionHeading("Memory — exists + remove(key) + allKeys")
    addActionButton("exists(key) TTL sample slot") { [weak self] in self?.memExistsSample() }
    addActionButton("remove(key) TTL sample (single entry)") { [weak self] in self?.memRemoveSampleKey() }
    addActionButton("allKeys() in-memory index") { [weak self] in self?.memListKeys() }

    addSectionHeading("Async facades (StorageAsync.swift)")
    addActionButton("async set + async value (UserDefaults, String)") { [weak self] in self?.runAsyncUDSetValue() }
    addActionButton("async exists + async allKeys (UserDefaults)") { [weak self] in self?.runAsyncUDExistsAllKeys() }
    addActionButton("async remove(key) lastUsername") { [weak self] in self?.runAsyncUDRemove() }
    addActionButton("async set + value (File, Codable profile)") { [weak self] in self?.runAsyncFileProfile() }
    addActionButton("async set + value (Keychain, token)") { [weak self] in self?.runAsyncKeychainToken() }
    addActionButton("async purgeExpired (UserDefaults)") { [weak self] in self?.runAsyncUDPurge() }
    addActionButton("async removeAll (memory only)") { [weak self] in self?.runAsyncMemoryRemoveAll() }

    addSectionHeading("Bulk operations")
    addActionButton("Purge expired (UserDefaults + File + Keychain + Memory)") { [weak self] in
      self?.purgeAllExpired()
    }
    addActionButton("removeAll — memory only") { [weak self] in self?.clearMemory() }
    addActionButton("removeAll — UserDefaults (prefixed keys only)") { [weak self] in self?.clearUserDefaults() }
    addActionButton("removeAll — Keychain service") { [weak self] in self?.clearKeychain() }
    addActionButton("removeAll — file blobs + index") { [weak self] in self?.clearFiles() }

    addSectionHeading("Log")
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }

  private func addSectionHeading(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    label.numberOfLines = 0
    label.accessibilityTraits.insert(.header)
    contentStack.addArrangedSubview(label)
    contentStack.setCustomSpacing(12, after: label)
  }

  private func addActionButton(_ title: String, handler: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.lineBreakMode = .byWordWrapping
    button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    contentStack.addArrangedSubview(button)
  }

  // MARK: - Logging (@MainActor)

  private func appendLog(_ message: String) {
    let prefix = DateFormatter.fkStorageLogFormatter.string(from: Date())
    let line = "[\(prefix)] \(message)\n"
    logView.text.append(line)
    let end = logView.text.count
    logView.scrollRangeToVisible(NSRange(location: max(end - 1, 0), length: 1))
  }

  private func clearLog() {
    logView.text = ""
  }

  // MARK: - UserDefaults

  private func udIncrementLaunchCount() {
    let key = FKStorageExampleKey.launchCount.fullKey
    do {
      let current = (try? userDefaultsStorage.value(key: key, as: Int.self)) ?? 0
      try userDefaultsStorage.set(current + 1, key: key)
      appendLog("UD: launchCount = \(current + 1)")
    } catch {
      appendLog("UD: increment error: \(error)")
    }
  }

  private func udReadLaunchCount() {
    let key = FKStorageExampleKey.launchCount.fullKey
    do {
      let n = try userDefaultsStorage.value(key: key, as: Int.self)
      appendLog("UD: launchCount = \(n)")
    } catch {
      appendLog("UD: read launchCount: \(error.localizedDescription)")
    }
  }

  private func udSetDarkMode() {
    let key = FKStorageExampleKey.prefersDarkMode.fullKey
    do {
      try userDefaultsStorage.set(true, key: key)
      appendLog("UD: prefersDarkMode stored as true")
    } catch {
      appendLog("UD: set dark mode error: \(error)")
    }
  }

  private func udReadDarkMode() {
    let key = FKStorageExampleKey.prefersDarkMode.fullKey
    do {
      let v = try userDefaultsStorage.value(key: key, as: Bool.self)
      appendLog("UD: prefersDarkMode = \(v)")
    } catch {
      appendLog("UD: read dark mode: \(error.localizedDescription)")
    }
  }

  private func udListKeys() {
    do {
      let keys = try userDefaultsStorage.allKeys()
      appendLog("UD: allKeys count=\(keys.count) -> \(keys.joined(separator: ", "))")
    } catch {
      appendLog("UD: allKeys error: \(error)")
    }
  }

  private func udExistsLaunchCount() {
    let key = FKStorageExampleKey.launchCount.fullKey
    let ok = userDefaultsStorage.exists(key: key)
    appendLog("UD: exists(launchCount) = \(ok)")
  }

  private func udRemoveDarkModeKey() {
    let key = FKStorageExampleKey.prefersDarkMode.fullKey
    do {
      try userDefaultsStorage.remove(key: key)
      appendLog("UD: remove(prefersDarkMode) done")
    } catch {
      appendLog("UD: remove error: \(error)")
    }
  }

  private func udSetTTLString() {
    let key = FKStorageExampleKey.userDefaultsTTLSample.fullKey
    do {
      try userDefaultsStorage.set("ttl_user_defaults", key: key, ttl: 8)
      appendLog("UD: stored String with TTL 8s under userDefaultsTTLSample")
    } catch {
      appendLog("UD: TTL set error: \(error)")
    }
  }

  private func udReadTTLString() {
    let key = FKStorageExampleKey.userDefaultsTTLSample.fullKey
    do {
      let s = try userDefaultsStorage.value(key: key, as: String.self)
      appendLog("UD: TTL sample value = \(s)")
    } catch {
      appendLog("UD: TTL read: \(error.localizedDescription)")
    }
  }

  private func udPurgeExpiredOnly() {
    do {
      try userDefaultsStorage.purgeExpired()
      appendLog("UD: purgeExpired() finished")
    } catch {
      appendLog("UD: purgeExpired error: \(error)")
    }
  }

  // MARK: - Keychain

  private func kcSaveToken() {
    let key = FKStorageExampleKey.accessToken.fullKey
    let payload = FKStorageExampleAuthToken(token: "example-access-token", expiresAt: Date().timeIntervalSince1970 + 3600)
    do {
      try keychainStorage.set(payload, key: key)
      appendLog("KC: access token saved (no TTL wrapper on payload; optional API TTL is separate)")
    } catch {
      appendLog("KC: save token error: \(error)")
    }
  }

  private func kcSavePassword() {
    let key = FKStorageExampleKey.userPassword.fullKey
    let payload = FKStorageExamplePassword(account: "demo@example.com", secret: "do-not-log-in-production")
    do {
      try keychainStorage.set(payload, key: key)
      appendLog("KC: password payload saved")
    } catch {
      appendLog("KC: save password error: \(error)")
    }
  }

  private func kcReadSecrets() {
    let tKey = FKStorageExampleKey.accessToken.fullKey
    let pKey = FKStorageExampleKey.userPassword.fullKey
    do {
      let token = try keychainStorage.value(key: tKey, as: FKStorageExampleAuthToken.self)
      let pw = try keychainStorage.value(key: pKey, as: FKStorageExamplePassword.self)
      appendLog("KC: token prefix=\(token.token.prefix(8))… account=\(pw.account)")
    } catch {
      appendLog("KC: read secrets: \(error.localizedDescription)")
    }
  }

  private func kcRemoveToken() {
    let key = FKStorageExampleKey.accessToken.fullKey
    do {
      try keychainStorage.remove(key: key)
      appendLog("KC: access token removed")
    } catch {
      appendLog("KC: remove token error: \(error)")
    }
  }

  private func kcExistsToken() {
    let key = FKStorageExampleKey.accessToken.fullKey
    let ok = keychainStorage.exists(key: key)
    appendLog("KC: exists(accessToken) = \(ok)")
  }

  private func kcListKeys() {
    do {
      let keys = try keychainStorage.allKeys()
      appendLog("KC: allKeys count=\(keys.count) -> \(keys.joined(separator: ", "))")
    } catch {
      appendLog("KC: allKeys error: \(error)")
    }
  }

  private func kcSetShortTTLToken() {
    let key = FKStorageExampleKey.keychainTTLSample.fullKey
    let payload = FKStorageExampleAuthToken(token: "short-lived", expiresAt: Date().timeIntervalSince1970 + 10)
    do {
      try keychainStorage.set(payload, key: key, ttl: 5)
      appendLog("KC: stored token with storage TTL = 5s (keychainTTLSample)")
    } catch {
      appendLog("KC: TTL token set error: \(error)")
    }
  }

  private func kcReadShortTTLToken() {
    let key = FKStorageExampleKey.keychainTTLSample.fullKey
    do {
      let t = try keychainStorage.value(key: key, as: FKStorageExampleAuthToken.self)
      appendLog("KC: TTL sample token prefix=\(t.token.prefix(6))…")
    } catch {
      appendLog("KC: TTL read: \(error.localizedDescription)")
    }
  }

  // MARK: - File

  private func fileSaveProfile() {
    let key = FKStorageExampleKey.userProfile.fullKey
    let profile = FKStorageExampleUserProfile(id: 42, displayName: "Ada", email: "ada@example.com")
    do {
      try fileStorage.set(profile, key: key)
      appendLog("File: profile saved at key \(key)")
    } catch {
      appendLog("File: save profile error: \(error)")
    }
  }

  private func fileLoadProfile() {
    let key = FKStorageExampleKey.userProfile.fullKey
    do {
      let p = try fileStorage.value(key: key, as: FKStorageExampleUserProfile.self)
      appendLog("File: profile \(p.displayName) <\(p.email)> id=\(p.id)")
    } catch {
      appendLog("File: load profile: \(error.localizedDescription)")
    }
  }

  private func fileSaveImage() {
    let key = FKStorageExampleKey.imageBlob.fullKey
    let data = FKStorageExampleSampleImage.pngDataFromRenderedImage() ?? FKStorageExampleSampleImage.pngData()
    do {
      try fileStorage.set(data, key: key)
      appendLog("File: PNG bytes written, count=\(data.count)")
    } catch {
      appendLog("File: save image error: \(error)")
    }
  }

  private func fileLoadImage() {
    let key = FKStorageExampleKey.imageBlob.fullKey
    do {
      let data = try fileStorage.value(key: key, as: Data.self)
      appendLog("File: Data read, count=\(data.count)")
    } catch {
      appendLog("File: load image: \(error.localizedDescription)")
    }
  }

  private func fileSaveText() {
    let key = FKStorageExampleKey.textNote.fullKey
    do {
      try fileStorage.set("Line 1: plain String in FKFileStorage.\nLine 2: safe for notes.", key: key)
      appendLog("File: text note saved")
    } catch {
      appendLog("File: save text error: \(error)")
    }
  }

  private func fileSaveJSON() {
    let key = FKStorageExampleKey.jsonDocument.fullKey
    let doc = FKStorageExampleJSONDocument(title: "Demo", items: ["alpha", "bravo", "charlie"], revision: 3)
    do {
      try fileStorage.set(doc, key: key)
      appendLog("File: JSON document saved, revision=\(doc.revision)")
    } catch {
      appendLog("File: save JSON error: \(error)")
    }
  }

  private func fileShowDirectory() {
    appendLog("File: directoryURL = \(fileStorage.directoryURL.path)")
  }

  private func fileExistsProfile() {
    let key = FKStorageExampleKey.userProfile.fullKey
    let ok = fileStorage.exists(key: key)
    appendLog("File: exists(userProfile) = \(ok)")
  }

  private func fileRemoveTextNote() {
    let key = FKStorageExampleKey.textNote.fullKey
    do {
      try fileStorage.remove(key: key)
      appendLog("File: remove(textNote) done")
    } catch {
      appendLog("File: remove error: \(error)")
    }
  }

  private func fileListKeys() {
    do {
      let keys = try fileStorage.allKeys()
      appendLog("File: allKeys count=\(keys.count) -> \(keys.joined(separator: ", "))")
    } catch {
      appendLog("File: allKeys error: \(error)")
    }
  }

  private func fileSetTTLDocument() {
    let key = FKStorageExampleKey.fileTTLSample.fullKey
    let doc = FKStorageExampleJSONDocument(title: "TTL", items: ["tick"], revision: 1)
    do {
      try fileStorage.set(doc, key: key, ttl: 6)
      appendLog("File: JSON doc with TTL 6s stored (fileTTLSample)")
    } catch {
      appendLog("File: TTL set error: \(error)")
    }
  }

  private func fileReadTTLDocument() {
    let key = FKStorageExampleKey.fileTTLSample.fullKey
    do {
      let doc = try fileStorage.value(key: key, as: FKStorageExampleJSONDocument.self)
      appendLog("File: TTL doc title=\(doc.title) revision=\(doc.revision)")
    } catch {
      appendLog("File: TTL read: \(error.localizedDescription)")
    }
  }

  // MARK: - Memory

  private func memSetTTL() {
    let key = FKStorageExampleKey.ttlSample.fullKey
    do {
      try memoryStorage.set("expires_in_2_seconds", key: key, ttl: 2)
      appendLog("Mem: value set, TTL = 2s")
    } catch {
      appendLog("Mem: set error: \(error)")
    }
  }

  private func memReadTTL() {
    let key = FKStorageExampleKey.ttlSample.fullKey
    do {
      let s = try memoryStorage.value(key: key, as: String.self)
      appendLog("Mem: immediate read = \(s)")
    } catch {
      appendLog("Mem: read: \(error.localizedDescription)")
    }
  }

  private func memReadAfterDelay() {
    appendLog("Mem: scheduling read after 3s …")
    Task { [weak self] in
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      guard let self else { return }
      let key = FKStorageExampleKey.ttlSample.fullKey
      do {
        let s = try self.memoryStorage.value(key: key, as: String.self)
        await MainActor.run { self.appendLog("Mem: delayed read still got value: \(s)") }
      } catch {
        await MainActor.run {
          self.appendLog("Mem: delayed read (expected notFound after TTL): \(error.localizedDescription)")
        }
      }
    }
  }

  private func memExistsSample() {
    let key = FKStorageExampleKey.ttlSample.fullKey
    let ok = memoryStorage.exists(key: key)
    appendLog("Mem: exists(ttlSample) = \(ok)")
  }

  private func memRemoveSampleKey() {
    let key = FKStorageExampleKey.ttlSample.fullKey
    do {
      try memoryStorage.remove(key: key)
      appendLog("Mem: remove(ttlSample) done")
    } catch {
      appendLog("Mem: remove error: \(error)")
    }
  }

  private func memListKeys() {
    do {
      let keys = try memoryStorage.allKeys()
      appendLog("Mem: allKeys count=\(keys.count) -> \(keys.joined(separator: ", "))")
    } catch {
      appendLog("Mem: allKeys error: \(error)")
    }
  }

  // MARK: - Async facades

  private func runAsyncUDSetValue() {
    let key = FKStorageExampleKey.lastUsername.fullKey
    Task { [weak self] in
      guard let self else { return }
      do {
        try await userDefaultsStorage.set("async_demo_user", key: key, ttl: nil)
        // `try await storage.value(...)` on concrete backends can resolve to the synchronous requirement
        // without a suspension point; this matches the `Task` hop used in `StorageAsync.swift`.
        let name = try await Task { [userDefaultsStorage] in
          try userDefaultsStorage.value(key: key, as: String.self)
        }.value
        await MainActor.run {
          self.appendLog("Async UD: set + value -> \(name)")
        }
      } catch {
        await MainActor.run { self.appendLog("Async UD set/value: \(error.localizedDescription)") }
      }
    }
  }

  private func runAsyncUDExistsAllKeys() {
    Task { [weak self] in
      guard let self else { return }
      let launchKey = FKStorageExampleKey.launchCount.fullKey
      let exists = await userDefaultsStorage.exists(key: launchKey)
      do {
        let keys = try await userDefaultsStorage.allKeys()
        await MainActor.run {
          self.appendLog("Async UD: exists(launchCount)=\(exists), allKeys count=\(keys.count)")
        }
      } catch {
        await MainActor.run { self.appendLog("Async UD allKeys: \(error.localizedDescription)") }
      }
    }
  }

  private func runAsyncUDRemove() {
    let key = FKStorageExampleKey.lastUsername.fullKey
    Task { [weak self] in
      guard let self else { return }
      do {
        try await userDefaultsStorage.remove(key: key)
        let stillThere = await userDefaultsStorage.exists(key: key)
        await MainActor.run {
          self.appendLog("Async UD: remove(lastUsername) done, exists=\(stillThere)")
        }
      } catch {
        await MainActor.run { self.appendLog("Async UD remove: \(error.localizedDescription)") }
      }
    }
  }

  private func runAsyncFileProfile() {
    let key = FKStorageExampleKey.userProfile.fullKey
    let profile = FKStorageExampleUserProfile(id: 7, displayName: "Async", email: "async@example.com")
    Task { [weak self] in
      guard let self else { return }
      do {
        try await fileStorage.set(profile, key: key, ttl: nil)
        let read = try await Task { [fileStorage] in
          try fileStorage.value(key: key, as: FKStorageExampleUserProfile.self)
        }.value
        await MainActor.run {
          self.appendLog("Async File: round-trip profile email=\(read.email)")
        }
      } catch {
        await MainActor.run { self.appendLog("Async File: \(error.localizedDescription)") }
      }
    }
  }

  private func runAsyncKeychainToken() {
    let key = FKStorageExampleKey.accessToken.fullKey
    let payload = FKStorageExampleAuthToken(token: "async-keychain-token", expiresAt: Date().timeIntervalSince1970 + 120)
    Task { [weak self] in
      guard let self else { return }
      do {
        try await keychainStorage.set(payload, key: key, ttl: nil)
        let t = try await Task { [keychainStorage] in
          try keychainStorage.value(key: key, as: FKStorageExampleAuthToken.self)
        }.value
        await MainActor.run {
          self.appendLog("Async KC: token round-trip prefix=\(t.token.prefix(8))…")
        }
      } catch {
        await MainActor.run { self.appendLog("Async KC: \(error.localizedDescription)") }
      }
    }
  }

  private func runAsyncUDPurge() {
    Task { [weak self] in
      guard let self else { return }
      do {
        try await userDefaultsStorage.purgeExpired()
        await MainActor.run { self.appendLog("Async UD: purgeExpired() completed") }
      } catch {
        await MainActor.run { self.appendLog("Async UD purge: \(error.localizedDescription)") }
      }
    }
  }

  private func runAsyncMemoryRemoveAll() {
    Task { [weak self] in
      guard let self else { return }
      do {
        try await memoryStorage.removeAll()
        await MainActor.run { self.appendLog("Async Mem: removeAll() completed") }
      } catch {
        await MainActor.run { self.appendLog("Async Mem removeAll: \(error.localizedDescription)") }
      }
    }
  }

  // MARK: - Bulk

  private func purgeAllExpired() {
    do {
      try userDefaultsStorage.purgeExpired()
      try fileStorage.purgeExpired()
      try keychainStorage.purgeExpired()
      try memoryStorage.purgeExpired()
      appendLog("Purge: all backends completed purgeExpired()")
    } catch {
      appendLog("Purge: error \(error)")
    }
  }

  private func clearMemory() {
    do {
      try memoryStorage.removeAll()
      appendLog("removeAll: memory cleared")
    } catch {
      appendLog("removeAll memory: \(error)")
    }
  }

  private func clearUserDefaults() {
    do {
      try userDefaultsStorage.removeAll()
      appendLog("removeAll: UserDefaults (prefixed keys only)")
    } catch {
      appendLog("removeAll UD: \(error)")
    }
  }

  private func clearKeychain() {
    do {
      try keychainStorage.removeAll()
      appendLog("removeAll: Keychain items for this service")
    } catch {
      appendLog("removeAll KC: \(error)")
    }
  }

  private func clearFiles() {
    do {
      try fileStorage.removeAll()
      appendLog("removeAll: file storage directory reset for this instance")
    } catch {
      appendLog("removeAll file: \(error)")
    }
  }
}

// MARK: - Date formatting

private extension DateFormatter {
  static let fkStorageLogFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "HH:mm:ss"
    return f
  }()
}
