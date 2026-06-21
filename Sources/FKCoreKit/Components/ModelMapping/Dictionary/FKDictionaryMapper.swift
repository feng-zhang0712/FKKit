import Foundation

/// Protocol for models mapped manually from dynamic JSON dictionaries.
public protocol FKMappable: Sendable {
  /// Creates a model from a mapping context.
  init(map: FKMap) throws
}

/// Opt-in declaration of top-level JSON keys consumed by an ``FKMappable`` model.
///
/// Conform when ``FKModelMappingConfiguration/unknownKeyStrategy`` is ``FKUnknownKeyStrategy/fail``
/// and the payload should reject unexpected keys.
public protocol FKMappableKnownKeys {
  /// Top-level dictionary keys read by the model's ``FKMappable`` initializer.
  static var mappingKeys: Set<String> { get }
}

/// Maps dynamic dictionaries to Swift models without a JSON re-serialization round trip.
public struct FKDictionaryMapper: Sendable {
  private let configuration: FKModelMappingConfiguration
  private let transformRegistry: FKTransformRegistry

  /// Creates a dictionary mapper.
  public init(
    configuration: FKModelMappingConfiguration = .standard,
    transformRegistry: FKTransformRegistry = .default
  ) {
    self.configuration = configuration
    self.transformRegistry = transformRegistry
  }

  /// Decodes a model from a dictionary.
  public func decode<T>(_ type: T.Type, from dictionary: [String: Any]) throws -> T where T: FKMappable {
    try validatePayload(dictionary)
    try validateKnownKeysIfNeeded(for: type, in: dictionary)

    let map = FKMap(
      root: dictionary,
      configuration: configuration,
      transformRegistry: transformRegistry
    )
    return try T(map: map)
  }

  /// Decodes a model leniently and returns warnings when present.
  public func decodeLenient<T>(_ type: T.Type, from dictionary: [String: Any]) throws -> FKMappingResult<T>
    where T: FKMappable {
    try validatePayload(dictionary)
    try validateKnownKeysIfNeeded(for: type, in: dictionary)

    var lenientConfiguration = configuration
    lenientConfiguration.mappingMode = .lenient
    let map = FKMap(
      root: dictionary,
      configuration: lenientConfiguration,
      transformRegistry: transformRegistry
    )
    let value = try T(map: map)
    return FKMappingResult(value: value, warnings: map.collectedWarnings)
  }

  private func validatePayload(_ dictionary: [String: Any]) throws {
    _ = try FKJSONParser.parseJSONObject(
      from: dictionary,
      maxDepth: configuration.maxDepth,
      maxArrayCount: configuration.maxArrayCount
    )
  }

  private func validateKnownKeysIfNeeded<T>(for type: T.Type, in dictionary: [String: Any]) throws {
    guard configuration.unknownKeyStrategy == .fail else { return }
    let expected = expectedKeys(for: type)
    guard !expected.isEmpty else { return }
    try validateKnownKeys(in: dictionary, expectedKeys: expected)
  }

  private func validateKnownKeys(in dictionary: [String: Any], expectedKeys: Set<String>) throws {
    let unknown = Set(dictionary.keys).subtracting(expectedKeys)
    guard unknown.isEmpty else {
      throw FKMappingError.invalidPath(
        path: unknown.sorted().joined(separator: ", "),
        reason: "Unknown keys are not allowed in strict mode."
      )
    }
  }

  private func expectedKeys<T>(for type: T.Type) -> Set<String> {
    guard let knownKeys = type as? any FKMappableKnownKeys.Type else {
      return []
    }
    return knownKeys.mappingKeys
  }
}
