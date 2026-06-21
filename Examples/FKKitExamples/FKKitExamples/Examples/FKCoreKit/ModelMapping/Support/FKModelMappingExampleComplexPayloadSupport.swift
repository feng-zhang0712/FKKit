import FKCoreKit
import Foundation

/// Parses mixed backend date strings (ISO-8601, spaced timestamps, epoch milliseconds).
nonisolated func fkModelMappingExampleFlexibleDate(from value: Any?) throws -> Date? {
  if let milliseconds = value as? Int {
    return Date(timeIntervalSince1970: Double(milliseconds) / 1_000)
  }
  if let milliseconds = value as? Double {
    return Date(timeIntervalSince1970: milliseconds / 1_000)
  }
  guard let string = value as? String else { return nil }
  let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty else { return nil }

  if let isoDate = ISO8601DateFormatter().date(from: trimmed) {
    return isoDate
  }

  let normalized = trimmed.replacingOccurrences(
    of: #"(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})"#,
    with: "$1 $2",
    options: .regularExpression
  )
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter.date(from: normalized)
}

/// Support types for the complex workspace hub fixture scenario.
enum FKModelMappingExampleComplexPayloadSupport {
  static let fixtureName = "fixture_complex_workspace_hub"

  /// Mapping preset for nested paths, loose scalars, envelopes, and mixed dates.
  static var mappingConfiguration: FKModelMappingConfiguration {
    var configuration = FKModelMappingConfiguration.lenientAPI
    configuration.keyStrategy = .useDefaultKeys
    configuration.nilValueStrategy = [.treatNullAsNil, .treatEmptyStringAsNil]
    configuration.dateDecoding = .custom { value in
      try fkModelMappingExampleFlexibleDate(from: value)
    }
    configuration.envelope = .standard
    return configuration
  }

  /// Loads the bundled complex workspace hub fixture.
  static func loadFixture() throws -> Data {
    try FKMappingFixture.data(named: fixtureName)
  }

  /// Returns a short structural summary of the fixture without fully decoding models.
  static func fixtureSummary(from data: Data) throws -> String {
    let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let payload = object["data"] as! [String: Any]
    let feedPage = payload["feed_page"] as! [String: Any]
    let records = feedPage["records"] as! [Any]
    let workspace = payload["workspace"] as! [String: Any]
    return """
    topLevelKeys=\(object.keys.sorted().joined(separator: ", "))
    payloadKeys=\(payload.keys.count)
    workspaceKeys=\(workspace.keys.count)
    feedRecords=\(records.count)
    bytes=\(data.count)
    """
  }
}

/// Decodes a JSON object embedded in a string field.
struct FKModelMappingDemoEmbeddedJSONObjectTransform<Value: Decodable & Sendable>: FKValueTransform, Sendable {
  typealias Object = Value
  typealias JSON = Any

  init() {}

  func transformFromJSON(_ value: Any?) throws -> Value? {
    guard let value else { return nil }
    if let string = value as? String {
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      guard let data = trimmed.data(using: .utf8) else { return nil }
      return try JSONDecoder().decode(Value.self, from: data)
    }
    if let dictionary = value as? [String: Any] {
      let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
      return try JSONDecoder().decode(Value.self, from: data)
    }
    return nil
  }

  func transformToJSON(_ value: Value?) throws -> Any? {
    nil
  }
}

/// Decodes a JSON array embedded in a string field.
struct FKModelMappingDemoEmbeddedJSONArrayTransform<Element: Codable & Sendable>: FKValueTransform, Sendable {
  typealias Object = [Element]
  typealias JSON = Any

  init() {}

  func transformFromJSON(_ value: Any?) throws -> [Element]? {
    guard let value else { return nil }
    if let string = value as? String {
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      guard let data = trimmed.data(using: .utf8) else { return nil }
      return try JSONDecoder().decode([Element].self, from: data)
    }
    if let array = value as? [Any] {
      let data = try JSONSerialization.data(withJSONObject: array, options: [])
      return try JSONDecoder().decode([Element].self, from: data)
    }
    return nil
  }

  func transformToJSON(_ value: [Element]?) throws -> Any? {
    guard let value else { return nil }
    let data = try JSONEncoder().encode(value)
    return String(data: data, encoding: .utf8)
  }
}
