import Foundation

/// Stores a remote key name for documentation and helper APIs.
///
/// This wrapper does **not** change synthesized ``Codable`` key resolution.
/// Use explicit ``CodingKeys`` for renamed fields, or ``FKMappable`` / ``FKMap`` for nested paths.
@propertyWrapper
public struct FKMappedKey<Value: Codable & Sendable>: Codable, Sendable {
  /// Wrapped model value.
  public var wrappedValue: Value
  /// Remote JSON key or path referenced by helper APIs.
  public let remoteKey: String

  /// Creates a mapped key wrapper.
  public init(wrappedValue: Value, _ remoteKey: String) {
    self.wrappedValue = wrappedValue
    self.remoteKey = remoteKey
  }

  public init(from decoder: Decoder) throws {
    wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    remoteKey = ""
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue)
  }
}

/// Supplies a default value when a keyed value is missing or null.
@propertyWrapper
public struct FKDefault<Value: Codable & Sendable>: Codable, Sendable {
  /// Wrapped model value.
  public var wrappedValue: Value

  /// Creates a default wrapper using the wrapped value as the fallback.
  public init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      throw DecodingError.valueNotFound(
        Value.self,
        .init(codingPath: decoder.codingPath, debugDescription: "Missing default for FKDefault")
      )
    }
    wrappedValue = try container.decode(Value.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue)
  }
}

public extension KeyedDecodingContainer {
  /// Decodes a value or returns the provided default when the key is missing or null.
  func decode<T: Codable & Sendable>(
    _ type: FKDefault<T>.Type,
    forKey key: Key,
    default defaultValue: T
  ) throws -> FKDefault<T> {
    if let value = try decodeIfPresent(T.self, forKey: key) {
      return FKDefault(wrappedValue: value)
    }
    return FKDefault(wrappedValue: defaultValue)
  }
}

/// Applies a value transform to a Codable property.
@propertyWrapper
public struct FKTransform<Value: Codable & Sendable, Transform: FKValueTransform>: Codable, Sendable
where Transform.Object == Value {
  /// Wrapped model value.
  public var wrappedValue: Value
  private let transform: Transform

  /// Creates a transform wrapper.
  public init(wrappedValue: Value, _ transform: Transform) {
    self.wrappedValue = wrappedValue
    self.transform = transform
  }

  public init(from decoder: Decoder) throws {
    transform = Transform()
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      throw DecodingError.valueNotFound(
        Value.self,
        .init(codingPath: decoder.codingPath, debugDescription: "Null transform input")
      )
    }
    let raw = try FKFlexibleJSONDecoder.decodeRawValue(from: container)
    guard let value = try transform.transformFromJSON(raw) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "Transform returned nil")
      )
    }
    wrappedValue = value
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    let raw = try transform.transformToJSON(wrappedValue)
    try container.encode(FKFlexibleJSONEncoder.encode(raw))
  }
}

/// Treats empty strings as nil for optional properties.
@propertyWrapper
public struct FKOptionalValue<Value: Codable & Sendable>: Codable, Sendable {
  /// Wrapped optional value.
  public var wrappedValue: Value?

  /// Creates an optional mapping wrapper.
  public init(wrappedValue: Value? = nil) {
    self.wrappedValue = wrappedValue
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      wrappedValue = nil
      return
    }

    if Value.self == String.self {
      let string = try container.decode(String.self)
      wrappedValue = string.fk_isBlank ? nil : (string as! Value)
      return
    }

    wrappedValue = try container.decode(Value.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if let wrappedValue {
      try container.encode(wrappedValue)
    } else {
      try container.encodeNil()
    }
  }
}

/// Decodes arrays while skipping invalid elements instead of failing the entire container.
@propertyWrapper
public struct FKLossyArray<Element: Codable & Sendable>: Codable, Sendable {
  /// Wrapped array value.
  public var wrappedValue: [Element]

  /// Creates a lossy array wrapper.
  public init(wrappedValue: [Element] = []) {
    self.wrappedValue = wrappedValue
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var elements: [Element] = []
    while !container.isAtEnd {
      if let element = try? container.decode(Element.self) {
        elements.append(element)
      } else {
        _ = try? container.decode(FKFlexibleJSON.self)
      }
    }
    wrappedValue = elements
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for element in wrappedValue {
      try container.encode(element)
    }
  }
}

/// Internal flexible JSON token used to skip invalid lossy array elements.
struct FKFlexibleJSON: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() { return }
    if (try? container.decode(Bool.self)) != nil { return }
    if (try? container.decode(Double.self)) != nil { return }
    if (try? container.decode(String.self)) != nil { return }
    if (try? container.decode([FKFlexibleJSON].self)) != nil { return }
    if (try? container.decode([String: FKFlexibleJSON].self)) != nil { return }
    throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON token"))
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encodeNil()
  }
}

enum FKFlexibleJSONDecoder {
  static func decodeRawValue(from container: SingleValueDecodingContainer) throws -> Any? {
    if container.decodeNil() { return nil }
    if let bool = try? container.decode(Bool.self) { return bool }
    if let int = try? container.decode(Int.self) { return int }
    if let double = try? container.decode(Double.self) { return double }
    if let string = try? container.decode(String.self) { return string }
    return nil
  }
}

enum FKFlexibleJSONEncoder {
  static func encode(_ value: Any?) -> FKFlexibleEncodable {
    FKFlexibleEncodable(value: value)
  }
}

struct FKFlexibleEncodable: Encodable {
  let value: Any?

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case nil:
      try container.encodeNil()
    case let bool as Bool:
      try container.encode(bool)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let string as String:
      try container.encode(string)
    default:
      throw FKMappingError.encodingFailed(underlying: FKMappingError.typeMismatch(path: "", expected: "JSON", actual: String(describing: value)))
    }
  }
}
