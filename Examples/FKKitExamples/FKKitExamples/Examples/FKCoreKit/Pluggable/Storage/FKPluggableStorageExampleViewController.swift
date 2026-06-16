import FKCoreKit
import UIKit

/// Demonstrates `FKKeyValueStoring`, `FKCodableStoring`, and Storage-module bridging.
@MainActor
final class FKPluggableStorageExampleViewController: FKPluggableExampleBaseViewController {

  private let storage = FKInMemoryKeyValueStore()
  private lazy var bridgedStorage: FKCodableStoragePluggableAdapter = {
    FKCodableStoragePluggableAdapter(
      storage: FKUserDefaultsStorage(keyPrefix: "fk.examples.pluggable."),
      keyPrefix: "pluggable"
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Storage"

    addActionButton("1) FKInMemoryKeyValueStore — set raw Data") { [weak self] in
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
    addActionButton("3) FKCodableStoring JSON via FKPluggableJSONCodec") { [weak self] in
      guard let self else { return }
      do {
        let profile = DemoStoredProfile(name: "Frank", tier: "gold")
        let data = try profile.encodedData()
        try storage.set(data, forKey: "profile")
        let decoded = try storage.data(forKey: "profile").flatMap { try DemoStoredProfile.decoded(from: $0) }
        appendOutput("Stored + decoded: \(decoded?.name ?? "nil") / \(decoded?.tier ?? "nil")")
      } catch {
        appendOutput("Error: \(error)")
      }
    }
    addActionButton("4) FKCodableStoragePluggableAdapter bridge") { [weak self] in
      guard let self else { return }
      do {
        try bridgedStorage.set(Data("bridged".utf8), forKey: "bridge_key")
        let data = try bridgedStorage.data(forKey: "bridge_key")
        let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? "(nil)"
        appendOutput("Bridged read: \(text)")
      } catch {
        appendOutput("Bridge error: \(error)")
      }
    }
    addActionButton("5) remove(forKey:)") { [weak self] in
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
