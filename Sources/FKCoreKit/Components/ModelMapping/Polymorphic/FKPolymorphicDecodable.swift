import Foundation

/// Protocol for models decoded using a discriminator field and a static type registry.
public protocol FKPolymorphicDecodable: Sendable {
  /// JSON key containing the type discriminator.
  static var discriminatorKey: String { get }
  /// Decodes a concrete instance for the given discriminator value.
  static func decode(from map: FKMap, typeValue: String) throws -> Self
}

/// Static registry for polymorphic decoders keyed by discriminator value.
public struct FKPolymorphicRegistry: Sendable {
  private let decoders: [String: @Sendable (FKMap) throws -> any Sendable]

  /// Creates an empty registry.
  public init() {
    decoders = [:]
  }

  private init(decoders: [String: @Sendable (FKMap) throws -> any Sendable]) {
    self.decoders = decoders
  }

  /// Registers a decoder for a discriminator value.
  public func registering<T: Sendable>(
    _ typeValue: String,
    decode: @escaping @Sendable (FKMap) throws -> T
  ) -> FKPolymorphicRegistry {
    var copy = decoders
    copy[typeValue] = { map in try decode(map) }
    return FKPolymorphicRegistry(decoders: copy)
  }

  /// Decodes a value from a map using the registry.
  public func decode<T>(
    from map: FKMap,
    typeValue: String,
    as type: T.Type
  ) throws -> T where T: Sendable {
    guard let decoder = decoders[typeValue] else {
      throw FKMappingError.typeMismatch(
        path: map.collectedWarnings.first?.path ?? typeValue,
        expected: String(describing: T.self),
        actual: typeValue
      )
    }
    guard let value = try decoder(map) as? T else {
      throw FKMappingError.typeMismatch(
        path: typeValue,
        expected: String(describing: T.self),
        actual: String(describing: typeValue)
      )
    }
    return value
  }
}

public extension FKPolymorphicDecodable {
  /// Default discriminator key used by many APIs.
  static var discriminatorKey: String { "type" }

  /// Decodes `Self` using a registry of nested decoders.
  static func decode(from map: FKMap, typeValue: String, registry: FKPolymorphicRegistry) throws -> Self {
    try registry.decode(from: map, typeValue: typeValue, as: Self.self)
  }
}
