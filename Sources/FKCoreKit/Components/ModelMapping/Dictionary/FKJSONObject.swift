import Foundation

/// Dynamic JSON value wrapper used by ``FKJSONObject``.
public enum FKJSONValue: Sendable, Equatable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: FKJSONValue])
  case array([FKJSONValue])
  case null

  /// Converts a Foundation JSON object into ``FKJSONValue``.
  public static func from(_ value: Any?) -> FKJSONValue? {
    switch value {
    case nil, is NSNull:
      return .null
    case let string as String:
      return .string(string)
    case let bool as Bool:
      return .bool(bool)
    case let number as NSNumber:
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        return .bool(number.boolValue)
      }
      return .number(number.doubleValue)
    case let int as Int:
      return .number(Double(int))
    case let double as Double:
      return .number(double)
    case let dictionary as [String: Any]:
      var object: [String: FKJSONValue] = [:]
      for (key, value) in dictionary {
        object[key] = from(value) ?? .null
      }
      return .object(object)
    case let array as [Any]:
      return .array(array.compactMap(from))
    default:
      return nil
    }
  }
}

extension FKJSONValue: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .string(value):
      return value
    case let .number(value):
      return String(value)
    case let .bool(value):
      return String(value)
    case let .object(value):
      return "{\(value.count) keys}"
    case let .array(value):
      return "[\(value.count) items]"
    case .null:
      return "null"
    }
  }
}

/// Sendable-friendly JSON object view backed by a dictionary snapshot.
public struct FKJSONObject: @unchecked Sendable {
  private let storage: [String: Any]

  /// Creates a JSON object from a dictionary snapshot.
  public init(_ dictionary: [String: Any]) {
    storage = dictionary
  }

  /// Underlying dictionary snapshot.
  public var dictionary: [String: Any] {
    storage
  }

  /// Reads a value at a dot/bracket path.
  public subscript(path: String) -> FKJSONValue? {
    guard let value = FKJSONPathResolver.resolve(path: path, in: storage) else { return nil }
    return FKJSONValue.from(value)
  }
}
