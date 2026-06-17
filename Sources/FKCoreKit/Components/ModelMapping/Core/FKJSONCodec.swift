import Foundation

enum FKJSONCodecFactory {
  static func makeDecoder(configuration: FKModelMappingConfiguration) -> JSONDecoder {
    let decoder = JSONDecoder()
    applyKeyStrategy(to: decoder, configuration: configuration)
    applyDateDecoding(to: decoder, configuration: configuration)
    applyDataDecoding(to: decoder, configuration: configuration)
    return decoder
  }

  static func makeEncoder(configuration: FKModelMappingConfiguration) -> JSONEncoder {
    let encoder = JSONEncoder()
    applyKeyStrategy(to: encoder, configuration: configuration)
    applyDateEncoding(to: encoder, configuration: configuration)
    encoder.outputFormatting = configuration.outputFormatting
    return encoder
  }

  private static func applyKeyStrategy(to decoder: JSONDecoder, configuration: FKModelMappingConfiguration) {
    switch configuration.keyStrategy {
    case .useDefaultKeys:
      break
    case .convertFromSnakeCase:
      decoder.fk_applySnakeCaseKeys()
    case .convertToSnakeCase:
      break
    }
  }

  private static func applyKeyStrategy(to encoder: JSONEncoder, configuration: FKModelMappingConfiguration) {
    switch configuration.keyStrategy {
    case .useDefaultKeys:
      break
    case .convertFromSnakeCase:
      break
    case .convertToSnakeCase:
      encoder.fk_applySnakeCaseKeys()
    }
  }

  private static func applyDateDecoding(to decoder: JSONDecoder, configuration: FKModelMappingConfiguration) {
    switch configuration.dateDecoding {
    case .iso8601:
      decoder.fk_applyISO8601DateStrategy()
    case .secondsSince1970:
      decoder.dateDecodingStrategy = .secondsSince1970
    case .millisecondsSince1970:
      decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let milliseconds = try container.decode(Double.self)
        return Date(timeIntervalSince1970: milliseconds / 1_000)
      }
    case let .formatted(formatConfiguration):
      let formatter = FKDateTransformSupport.makeFormatter(formatConfiguration)
      decoder.dateDecodingStrategy = .formatted(formatter)
    case let .custom(handler):
      decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { throw DecodingError.valueNotFound(Date.self, .init(codingPath: decoder.codingPath, debugDescription: "Nil date")) }
        let rawValue: Any?
        if let string = try? container.decode(String.self) {
          rawValue = string
        } else if let double = try? container.decode(Double.self) {
          rawValue = double
        } else if let int = try? container.decode(Int.self) {
          rawValue = int
        } else {
          rawValue = nil
        }
        guard let date = try handler(rawValue) else {
          throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid date"))
        }
        return date
      }
    }
  }

  private static func applyDateEncoding(to encoder: JSONEncoder, configuration: FKModelMappingConfiguration) {
    switch configuration.dateEncoding {
    case .iso8601:
      encoder.fk_applyISO8601DateStrategy()
    case .secondsSince1970:
      encoder.dateEncodingStrategy = .secondsSince1970
    case .millisecondsSince1970:
      encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(date.timeIntervalSince1970 * 1_000)
      }
    case let .formatted(formatConfiguration):
      let formatter = FKDateTransformSupport.makeFormatter(formatConfiguration)
      encoder.dateEncodingStrategy = .formatted(formatter)
    case let .custom(handler):
      encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(AnyEncodable(value: try handler(date)))
      }
    }
  }

  private static func applyDataDecoding(to decoder: JSONDecoder, configuration: FKModelMappingConfiguration) {
    switch configuration.dataDecoding {
    case .base64:
      decoder.dataDecodingStrategy = .base64
    }
  }

  static func applyEncodeNullStrategy(to data: Data, configuration: FKModelMappingConfiguration) throws -> Data {
    guard configuration.encodeNullStrategy == .omitKey else { return data }
    return try FKJSONNullPolicy.stripNullKeys(from: data)
  }
}

enum FKJSONNullPolicy {
  static func stripNullKeys(from data: Data) throws -> Data {
    let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    let stripped = stripNulls(in: object)
    guard JSONSerialization.isValidJSONObject(stripped) else {
      throw FKMappingError.encodingFailed(underlying: FKMappingError.invalidJSON(underlying: nil))
    }
    return try JSONSerialization.data(withJSONObject: stripped, options: [])
  }

  private static func stripNulls(in value: Any) -> Any {
    if var dictionary = value as? [String: Any] {
      var result: [String: Any] = [:]
      result.reserveCapacity(dictionary.count)
      for (key, child) in dictionary {
        if child is NSNull { continue }
        result[key] = stripNulls(in: child)
      }
      return result
    }

    if let array = value as? [Any] {
      return array.map { stripNulls(in: $0) }
    }

    return value
  }
}

private struct AnyEncodable: Encodable {
  let value: Any

  init(value: Any) {
    self.value = value
  }

  func encode(to encoder: Encoder) throws {
    switch value {
    case let string as String:
      var container = encoder.singleValueContainer()
      try container.encode(string)
    case let int as Int:
      var container = encoder.singleValueContainer()
      try container.encode(int)
    case let double as Double:
      var container = encoder.singleValueContainer()
      try container.encode(double)
    case let bool as Bool:
      var container = encoder.singleValueContainer()
      try container.encode(bool)
    default:
      throw FKMappingError.encodingFailed(underlying: FKMappingError.typeMismatch(path: "", expected: "Encodable", actual: String(describing: type(of: value))))
    }
  }
}

/// JSON codec applying ``FKModelMappingConfiguration`` to Foundation coders.
public struct FKJSONCodec: Sendable {
  private let configuration: FKModelMappingConfiguration

  /// Creates a JSON codec.
  public init(configuration: FKModelMappingConfiguration = .standard) {
    self.configuration = configuration
  }

  /// Current mapping configuration snapshot.
  public var mappingConfiguration: FKModelMappingConfiguration {
    configuration
  }

  /// Builds a fresh ``JSONDecoder`` configured for this codec.
  public func makeDecoder() -> JSONDecoder {
    FKJSONCodecFactory.makeDecoder(configuration: configuration)
  }

  /// Builds a fresh ``JSONEncoder`` configured for this codec.
  public func makeEncoder() -> JSONEncoder {
    FKJSONCodecFactory.makeEncoder(configuration: configuration)
  }

  /// Decodes a model from JSON data.
  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    do {
      return try makeDecoder().decode(type, from: data)
    } catch {
      throw FKDecodingErrorMapper.map(error)
    }
  }

  /// Decodes a model from a UTF-8 JSON string.
  public func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
    guard let data = string.data(using: .utf8) else {
      throw FKMappingError.invalidJSON(underlying: FKJSONExtensionError.invalidUTF8)
    }
    return try decode(type, from: data)
  }

  /// Encodes a model to JSON data.
  public func encode<T: Encodable>(_ value: T) throws -> Data {
    do {
      let encoder = makeEncoder()
      let data = try encoder.encode(value)
      return try FKJSONCodecFactory.applyEncodeNullStrategy(to: data, configuration: configuration)
    } catch let error as FKMappingError {
      throw error
    } catch {
      throw FKMappingError.encodingFailed(underlying: error)
    }
  }

  /// Encodes a model to a UTF-8 JSON string.
  public func encodeString<T: Encodable>(_ value: T) throws -> String {
    let data = try encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
      throw FKMappingError.encodingFailed(underlying: FKJSONExtensionError.invalidUTF8)
    }
    return string
  }
}
