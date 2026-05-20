import FKCoreKit
import UIKit

/// Demonstrates `FKKeyValueStoring` and `FKCodableStoring` default JSON helpers.
@MainActor
final class FKPluggableStorageExampleViewController: FKPluggableExampleBaseViewController {

  private let storage = DemoMemoryStorage()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Storage"

    addActionButton("1) set raw Data (FKKeyValueStoring)") { [weak self] in
      guard let self else { return }
      do {
        try storage.set(Data("hello".utf8), forKey: "greeting")
        appendOutput("Stored raw data at key 'greeting'.")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("2) data(forKey:) + contains") { [weak self] in
      guard let self else { return }
      do {
        let data = try storage.data(forKey: "greeting")
        let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? "(nil)"
        appendOutput("Read: \(text), contains=\(storage.contains(key: "greeting"))")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("3) Encode + set Data (FKKeyValueStoring)") { [weak self] in
      guard let self else { return }
      do {
        let profile = DemoStoredProfile(name: "Frank", tier: "gold")
        try storage.set(profile.encodedData(), forKey: "profile")
        appendOutput("Stored profile JSON at key 'profile'.")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("4) FKPluggableJSONCodec + FKCodableStoring pattern") { [weak self] in
      guard let self else { return }
      do {
        let profile = DemoStoredProfile(name: "Frank", tier: "gold")
        let data = try FKPluggableJSONCodec.encode(["name": profile.name, "tier": profile.tier])
        try storage.set(data, forKey: "profile_codec")
        appendOutput("FKPluggableJSONCodec.encode → \(data.count) bytes")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("5) Read + decode profile") { [weak self] in
      guard let self else { return }
      do {
        guard let data = try storage.data(forKey: "profile") else {
          appendOutput("No data at 'profile'")
          return
        }
        let profile = try DemoStoredProfile.decoded(from: data)
        appendOutput("Decoded: \(profile)")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("6) remove(forKey:)") { [weak self] in
      guard let self else { return }
      do {
        try storage.remove(forKey: "greeting")
        appendOutput("Removed 'greeting', contains=\(storage.contains(key: "greeting"))")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }
}
