import Foundation

/// Converts loosely typed JSON values to Swift model values and back.
public protocol FKValueTransform: Sendable {
  associatedtype Object
  associatedtype JSON

  /// Creates a transform instance for property-wrapper decoding.
  init()

  /// Maps a JSON value to a model value.
  func transformFromJSON(_ value: Any?) throws -> Object?
  /// Maps a model value to a JSON value.
  func transformToJSON(_ value: Object?) throws -> Any?
}

/// Type-erased transform wrapper for registry storage.
public struct FKAnyValueTransform: Sendable {
  private let fromJSON: @Sendable (Any?) throws -> Any?
  private let toJSON: @Sendable (Any?) throws -> Any?

  /// Creates a type-erased transform.
  public init<T: FKValueTransform>(_ transform: T) {
    fromJSON = { try transform.transformFromJSON($0) }
    toJSON = { try transform.transformToJSON($0 as? T.Object) }
  }

  func transformFromJSON(_ value: Any?) throws -> Any? {
    try fromJSON(value)
  }

  func transformToJSON(_ value: Any?) throws -> Any? {
    try toJSON(value)
  }
}

/// Registry of custom transforms keyed by object type identifier.
public struct FKTransformRegistry: Sendable {
  private let transforms: [ObjectIdentifier: FKAnyValueTransform]

  /// Empty registry.
  public init() {
    transforms = [:]
  }

  private init(transforms: [ObjectIdentifier: FKAnyValueTransform]) {
    self.transforms = transforms
  }

  /// Registers a transform for its `Object` type.
  public func registering<T: FKValueTransform>(_ transform: T) -> FKTransformRegistry {
    var copy = transforms
    copy[ObjectIdentifier(T.Object.self)] = FKAnyValueTransform(transform)
    return FKTransformRegistry(transforms: copy)
  }

  /// Returns a registered transform when available.
  public func transform(for type: Any.Type) -> FKAnyValueTransform? {
    transforms[ObjectIdentifier(type)]
  }

  /// Default registry with built-in scalar transforms.
  public static let `default` = FKTransformRegistry()
    .registering(FKIntTransform())
    .registering(FKDoubleTransform())
    .registering(FKBoolTransform())
    .registering(FKStringTransform())
    .registering(FKURLTransform())
    .registering(FKDataTransform())
}

public extension FKValueTransform where Object == Int, JSON == Any {
  /// Shared lenient integer transform.
  static var lenient: Self { Self() }
}

public extension FKValueTransform where Object == Double, JSON == Any {
  /// Shared lenient double transform.
  static var lenient: Self { Self() }
}

public extension FKValueTransform where Object == Bool, JSON == Any {
  /// Shared lenient bool transform.
  static var lenient: Self { Self() }
}
