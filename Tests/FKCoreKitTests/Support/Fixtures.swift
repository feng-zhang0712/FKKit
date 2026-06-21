import Foundation
import FKCoreKit

/// Shared constants and sample models for FKCoreKitTests.
final class LockedCounter: @unchecked Sendable {
  private var value = 0
  private let lock = NSLock()

  func increment(by amount: Int = 1) {
    lock.lock()
    value += amount
    lock.unlock()
  }

  var current: Int {
    lock.lock()
    defer { lock.unlock() }
    return value
  }
}

/// Thread-safe string collector for observer callbacks in tests.
final class LockedStringCollector: @unchecked Sendable {
  private var values: [String] = []
  private let lock = NSLock()

  func append(_ value: String) {
    lock.lock()
    values.append(value)
    lock.unlock()
  }

  var snapshot: [String] {
    lock.lock()
    defer { lock.unlock() }
    return values
  }

  var count: Int {
    lock.lock()
    defer { lock.unlock() }
    return values.count
  }
}

enum Fixtures {
  enum Security {
    /// Known SHA-256 digest for `"hello"` (lowercase hex).
    static let sha256Hello = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

    /// Plaintext paired with ``sha256Hello``.
    static let samplePlaintext = "hello"

    /// 32-byte AES-256 key for deterministic encrypt/decrypt round-trip tests.
    static let aes256Key = Data(repeating: 0xAB, count: 32)

    /// 16-byte IV for AES-CBC tests.
    static let aesIV = Data(repeating: 0xCD, count: 16)
  }

  enum Storage {
    /// Sample Codable payload for memory/file storage tests.
    struct Profile: Codable, Sendable, Equatable {
      let id: Int
      let name: String
    }

    static let sampleProfile = Profile(id: 1, name: "FKKit")
    static let namespace = "com.fkkit.tests"
  }

  enum I18n {
    /// Flat translation table for dictionary localizer tests.
    static let flatDictionary: [String: [String: String]] = [
      "en": [
        "greeting": "Hello, {name}!",
        "welcome": "Welcome",
        "items.count": "%d items",
        "items.none": "No items",
      ],
      "zh-Hans": [
        "greeting": "你好，{name}！",
        "welcome": "欢迎",
        "items.count": "%d 项",
        "items.none": "暂无项目",
      ],
    ]
  }
}
