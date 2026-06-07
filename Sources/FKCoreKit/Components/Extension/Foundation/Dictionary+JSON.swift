import Foundation

public extension Dictionary {
  /// Returns a typed value for `key`.
  func fk_value<T>(for key: Key, as type: T.Type = T.self) -> T? {
    self[key] as? T
  }
}

public extension Dictionary where Key == String, Value == Any {
  /// Converts the dictionary to a JSON string when valid.
  func fk_jsonString(prettyPrinted: Bool = false) -> String? {
    guard JSONSerialization.isValidJSONObject(self) else { return nil }
    let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
    guard let data = try? JSONSerialization.data(withJSONObject: self, options: options) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// Decodes a `Decodable` model from the dictionary.
  func fk_decodeJSON<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? {
    guard JSONSerialization.isValidJSONObject(self),
          let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
      return nil
    }
    return try? decoder.decode(type, from: data)
  }
}

public extension Dictionary where Key == String, Value == Any? {
  /// Filters out `nil` values.
  func fk_compactValues() -> [String: Any] {
    reduce(into: [String: Any]()) { partial, pair in
      if let value = pair.value { partial[pair.key] = value }
    }
  }
}
