import Foundation

public extension Dictionary {
  /// Returns a new dictionary by merging `other`; duplicate keys keep values from `other`.
  func fk_merged(with other: [Key: Value]) -> [Key: Value] {
    merging(other) { _, new in new }
  }

  /// Maps keys while preserving values; duplicate mapped keys keep the last occurrence.
  func fk_mapKeys<NewKey: Hashable>(_ transform: (Key) throws -> NewKey) rethrows -> [NewKey: Value] {
    var result: [NewKey: Value] = [:]
    for (key, value) in self {
      result[try transform(key)] = value
    }
    return result
  }

  /// Maps values while preserving keys; stops at the first thrown error.
  func fk_mapValuesThrowing<NewValue>(_ transform: (Value) throws -> NewValue) rethrows -> [Key: NewValue] {
    var result: [Key: NewValue] = [:]
    result.reserveCapacity(count)
    for (key, value) in self {
      result[key] = try transform(value)
    }
    return result
  }
}
