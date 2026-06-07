import Foundation

/// Errors produced by JSON encoding and decoding helpers.
public enum FKJSONExtensionError: Error, Sendable {
  /// UTF-8 string conversion failed after encoding.
  case invalidUTF8
}

public extension Encodable {
  /// Encodes `self` to JSON data using `encoder`.
  func fk_jsonData(using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
    try encoder.encode(self)
  }

  /// Encodes `self` to a UTF-8 JSON string using `encoder`.
  func fk_jsonString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
    let data = try fk_jsonData(using: encoder)
    guard let string = String(data: data, encoding: .utf8) else {
      throw FKJSONExtensionError.invalidUTF8
    }
    return string
  }
}

public extension Decodable {
  /// Decodes `Self` from JSON data using `decoder`.
  static func fk_decoded(from data: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> Self {
    try decoder.decode(Self.self, from: data)
  }

  /// Decodes `Self` from a UTF-8 JSON string using `decoder`.
  static func fk_decoded(from string: String, using decoder: JSONDecoder = JSONDecoder()) throws -> Self {
    guard let data = string.data(using: .utf8) else {
      throw FKJSONExtensionError.invalidUTF8
    }
    return try fk_decoded(from: data, using: decoder)
  }
}
