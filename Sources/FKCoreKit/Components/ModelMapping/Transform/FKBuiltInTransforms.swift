import Foundation

/// Lenient integer transform backed by ``FKValueParsing``.
public struct FKIntTransform: FKValueTransform, Sendable {
  public typealias Object = Int
  public typealias JSON = Any

  /// Creates an integer transform.
  public init() {}

  public func transformFromJSON(_ value: Any?) throws -> Int? {
    guard let value else { return nil }
    if let int = FKValueParsing.int(from: value) { return int }
    throw FKMappingError.typeMismatch(
      path: "",
      expected: "Int",
      actual: String(describing: type(of: value))
    )
  }

  public func transformToJSON(_ value: Int?) throws -> Any? {
    value
  }
}

/// Lenient double transform backed by ``FKValueParsing``.
public struct FKDoubleTransform: FKValueTransform, Sendable {
  public typealias Object = Double
  public typealias JSON = Any

  /// Creates a double transform.
  public init() {}

  public func transformFromJSON(_ value: Any?) throws -> Double? {
    guard let value else { return nil }
    if let double = FKValueParsing.double(from: value) { return double }
    throw FKMappingError.typeMismatch(
      path: "",
      expected: "Double",
      actual: String(describing: type(of: value))
    )
  }

  public func transformToJSON(_ value: Double?) throws -> Any? {
    value
  }
}

/// Lenient bool transform for numeric and string payloads.
public struct FKBoolTransform: FKValueTransform, Sendable {
  public typealias Object = Bool
  public typealias JSON = Any

  /// Creates a bool transform.
  public init() {}

  public func transformFromJSON(_ value: Any?) throws -> Bool? {
    guard let value else { return nil }
    switch value {
    case let bool as Bool:
      return bool
    case let number as NSNumber:
      return number.boolValue
    case let string as String:
      switch string.lowercased() {
      case "true", "1", "yes":
        return true
      case "false", "0", "no":
        return false
      default:
        return nil
      }
    default:
      return nil
    }
  }

  public func transformToJSON(_ value: Bool?) throws -> Any? {
    value
  }
}

/// String transform accepting common scalar JSON types.
public struct FKStringTransform: FKValueTransform, Sendable {
  public typealias Object = String
  public typealias JSON = Any

  /// Creates a string transform.
  public init() {}

  public func transformFromJSON(_ value: Any?) throws -> String? {
    FKValueParsing.string(from: value)
  }

  public func transformToJSON(_ value: String?) throws -> Any? {
    value
  }
}

/// URL transform using absolute string representation.
public struct FKURLTransform: FKValueTransform, Sendable {
  public typealias Object = URL
  public typealias JSON = Any

  /// Creates a URL transform.
  public init() {}

  public func transformFromJSON(_ value: Any?) throws -> URL? {
    guard let string = FKValueParsing.string(from: value) else { return nil }
    return URL(string: string)
  }

  public func transformToJSON(_ value: URL?) throws -> Any? {
    value?.absoluteString
  }
}

/// Base64 data transform.
public struct FKDataTransform: FKValueTransform, Sendable {
  public typealias Object = Data
  public typealias JSON = Any

  private let maxLength: Int

  /// Creates a Base64 data transform with the default size limit.
  public init() {
    maxLength = 16_777_216
  }

  /// Creates a Base64 data transform.
  ///
  /// - Parameter maxLength: Maximum decoded byte length allowed for untrusted payloads.
  public init(maxLength: Int) {
    self.maxLength = maxLength
  }

  public func transformFromJSON(_ value: Any?) throws -> Data? {
    guard let string = FKValueParsing.string(from: value) else { return nil }
    guard let data = Data(base64Encoded: string) else {
      throw FKMappingError.typeMismatch(path: "", expected: "Base64 Data", actual: "String")
    }
    guard data.count <= maxLength else {
      throw FKMappingError.payloadLimitExceeded(reason: "Base64 payload exceeds maximum length.")
    }
    return data
  }

  public func transformToJSON(_ value: Data?) throws -> Any? {
    value?.base64EncodedString()
  }
}

/// Raw-representable enum transform with lenient raw value parsing.
public struct FKRawRepresentableTransform<Value: RawRepresentable & Sendable>: FKValueTransform, Sendable
where Value.RawValue: Codable & Sendable {
  public typealias Object = Value
  public typealias JSON = Any

  private let intTransform = FKIntTransform()
  private let stringTransform = FKStringTransform()

  /// Creates a raw-representable transform.
  public init() {}

  public func transformFromJSON(_ value: Any?) throws -> Value? {
    guard let value else { return nil }

    if let rawValue = value as? Value.RawValue {
      return Value(rawValue: rawValue)
    }

    if Value.RawValue.self == Int.self, let int = try intTransform.transformFromJSON(value) {
      return Value(rawValue: int as! Value.RawValue)
    }

    if Value.RawValue.self == String.self, let string = try stringTransform.transformFromJSON(value) {
      return Value(rawValue: string as! Value.RawValue)
    }

    return nil
  }

  public func transformToJSON(_ value: Value?) throws -> Any? {
    value?.rawValue
  }
}

enum FKDateTransformSupport {
  static func makeFormatter(_ configuration: FKDateFormatConfiguration) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = configuration.format
    formatter.locale = Locale(identifier: configuration.localeIdentifier)
    formatter.timeZone = TimeZone(identifier: configuration.timeZoneIdentifier) ?? .current
    return formatter
  }

  static func decode(
    _ value: Any?,
    strategy: FKDateDecodingStrategy
  ) throws -> Date? {
    guard let value else { return nil }

    switch strategy {
    case .iso8601:
      guard let string = value as? String else { return nil }
      return ISO8601DateFormatter().date(from: string)
        ?? makeFormatter(FKDateFormatConfiguration(format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")).date(from: string)
    case .secondsSince1970:
      if let double = FKValueParsing.double(from: value) { return Date(timeIntervalSince1970: double) }
      return nil
    case .millisecondsSince1970:
      if let double = FKValueParsing.double(from: value) { return Date(timeIntervalSince1970: double / 1_000) }
      return nil
    case let .formatted(configuration):
      guard let string = value as? String else { return nil }
      return makeFormatter(configuration).date(from: string)
    case let .custom(handler):
      return try handler(value)
    }
  }

  static func encode(
    _ date: Date?,
    strategy: FKDateEncodingStrategy
  ) throws -> Any? {
    guard let date else { return nil }
    switch strategy {
    case .iso8601:
      return ISO8601DateFormatter().string(from: date)
    case .secondsSince1970:
      return date.timeIntervalSince1970
    case .millisecondsSince1970:
      return date.timeIntervalSince1970 * 1_000
    case let .formatted(configuration):
      return makeFormatter(configuration).string(from: date)
    case let .custom(handler):
      return try handler(date)
    }
  }
}

/// Date transform delegating to ``FKDateDecodingStrategy`` / ``FKDateEncodingStrategy``.
public struct FKDateTransform: FKValueTransform, Sendable {
  public typealias Object = Date
  public typealias JSON = Any

  private let decoding: FKDateDecodingStrategy
  private let encoding: FKDateEncodingStrategy

  /// Creates a date transform with ISO-8601 strategies.
  public init() {
    decoding = .iso8601
    encoding = .iso8601
  }

  /// Creates a date transform.
  public init(
    decoding: FKDateDecodingStrategy = .iso8601,
    encoding: FKDateEncodingStrategy = .iso8601
  ) {
    self.decoding = decoding
    self.encoding = encoding
  }

  public func transformFromJSON(_ value: Any?) throws -> Date? {
    try FKDateTransformSupport.decode(value, strategy: decoding)
  }

  public func transformToJSON(_ value: Date?) throws -> Any? {
    try FKDateTransformSupport.encode(value, strategy: encoding)
  }
}
