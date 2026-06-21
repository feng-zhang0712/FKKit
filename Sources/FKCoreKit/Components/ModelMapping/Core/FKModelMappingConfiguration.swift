import Foundation

/// JSON key naming strategy for decode and encode paths.
public enum FKMappingKeyStrategy: Sendable, Equatable {
  /// Keep property names as JSON keys.
  case useDefaultKeys
  /// Convert snake_case JSON keys to camelCase Swift properties when decoding.
  case convertFromSnakeCase
  /// Convert camelCase Swift properties to snake_case JSON keys when encoding.
  case convertToSnakeCase
}

/// Behavior when unknown JSON keys are encountered.
public enum FKUnknownKeyStrategy: Sendable, Equatable {
  /// Ignore unknown keys (default JSONDecoder behavior).
  case ignore
  /// Fail decoding when unknown keys are present.
  case fail
}

/// Null and empty-value normalization rules.
public struct FKNilValueStrategy: Sendable, Equatable, OptionSet {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Treat JSON `null` as Swift `nil` for optional properties.
  public static let treatNullAsNil = FKNilValueStrategy(rawValue: 1 << 0)
  /// Treat empty or whitespace-only strings as `nil` for optional properties.
  public static let treatEmptyStringAsNil = FKNilValueStrategy(rawValue: 1 << 1)
  /// Treat numeric zero as `nil` for optional properties.
  public static let treatNSNumberZeroAsNil = FKNilValueStrategy(rawValue: 1 << 2)

  /// Default nil normalization.
  public static let standard: FKNilValueStrategy = [.treatNullAsNil]
}

/// Strict versus lenient mapping behavior.
public enum FKMappingMode: Sendable, Equatable {
  /// Fail fast on the first type mismatch.
  case strict
  /// Continue mapping when possible and collect warnings.
  case lenient
}

/// Null encoding behavior for optional properties.
public enum FKEncodeNullStrategy: Sendable, Equatable {
  /// Emit explicit JSON `null`.
  case encodeNull
  /// Omit keys whose values are `nil`.
  case omitKey
}

/// Sendable date format configuration for formatted decoding and encoding.
public struct FKDateFormatConfiguration: Sendable, Equatable {
  /// Date format template passed to `DateFormatter`.
  public var format: String
  /// BCP-47 locale identifier.
  public var localeIdentifier: String
  /// Time zone identifier.
  public var timeZoneIdentifier: String

  /// Creates a date format configuration.
  public init(
    format: String,
    localeIdentifier: String = "en_US_POSIX",
    timeZoneIdentifier: String = TimeZone.current.identifier
  ) {
    self.format = format
    self.localeIdentifier = localeIdentifier
    self.timeZoneIdentifier = timeZoneIdentifier
  }
}

/// Date decoding strategy applied by ``FKJSONCodec``.
public enum FKDateDecodingStrategy: Sendable {
  case iso8601
  case secondsSince1970
  case millisecondsSince1970
  case formatted(FKDateFormatConfiguration)
  case custom(@Sendable (Any?) throws -> Date?)
}

/// Date encoding strategy applied by ``FKJSONCodec``.
public enum FKDateEncodingStrategy: Sendable {
  case iso8601
  case secondsSince1970
  case millisecondsSince1970
  case formatted(FKDateFormatConfiguration)
  case custom(@Sendable (Date) throws -> Any)
}

/// Data decoding strategy for Base64 payloads.
public enum FKDataDecodingStrategy: Sendable, Equatable {
  case base64
}

/// Bool decoding strategy for loosely typed APIs.
public enum FKBoolDecodingStrategy: Sendable, Equatable {
  case jsonBool
  case numericOrString
}

/// Global mapping configuration shared by codecs, dictionary mappers, and envelopes.
public struct FKModelMappingConfiguration: Sendable {
  /// Key naming strategy.
  public var keyStrategy: FKMappingKeyStrategy
  /// Unknown key handling for dictionary mapping.
  public var unknownKeyStrategy: FKUnknownKeyStrategy
  /// Null and empty normalization flags.
  public var nilValueStrategy: FKNilValueStrategy
  /// Strict or lenient mapping mode.
  public var mappingMode: FKMappingMode
  /// Optional value encoding behavior.
  public var encodeNullStrategy: FKEncodeNullStrategy
  /// Date decoding strategy.
  public var dateDecoding: FKDateDecodingStrategy
  /// Date encoding strategy.
  public var dateEncoding: FKDateEncodingStrategy
  /// Data decoding strategy.
  public var dataDecoding: FKDataDecodingStrategy
  /// Bool decoding strategy.
  ///
  /// Applies to ``FKMap`` / ``FKDictionaryMapper`` paths. Standard ``JSONDecoder`` decoding
  /// ignores this flag unless you use ``FKTransform`` or custom ``Codable`` logic.
  public var boolDecoding: FKBoolDecodingStrategy
  /// Enables loose number parsing through ``FKValueParsing`` on dictionary mapping paths.
  public var lenientNumberParsing: Bool
  /// Maximum JSON nesting depth allowed when parsing untrusted payloads.
  public var maxDepth: Int
  /// Maximum array element count allowed when parsing untrusted payloads.
  public var maxArrayCount: Int
  /// Optional response envelope configuration.
  public var envelope: FKResponseEnvelopeConfiguration?
  /// Debug output formatting for encoded JSON.
  public var outputFormatting: JSONEncoder.OutputFormatting

  /// Default strict configuration.
  public static let standard = FKModelMappingConfiguration(
    keyStrategy: .useDefaultKeys,
    unknownKeyStrategy: .ignore,
    nilValueStrategy: .standard,
    mappingMode: .strict,
    encodeNullStrategy: .encodeNull,
    dateDecoding: .iso8601,
    dateEncoding: .iso8601,
    dataDecoding: .base64,
    boolDecoding: .jsonBool,
    lenientNumberParsing: false,
    maxDepth: 64,
    maxArrayCount: 10_000,
    envelope: nil,
    outputFormatting: []
  )

  /// Typical REST API preset with snake_case keys and ISO-8601 dates.
  public static let apiDefault = FKModelMappingConfiguration(
    keyStrategy: .convertFromSnakeCase,
    unknownKeyStrategy: .ignore,
    nilValueStrategy: .standard,
    mappingMode: .strict,
    encodeNullStrategy: .encodeNull,
    dateDecoding: .iso8601,
    dateEncoding: .iso8601,
    dataDecoding: .base64,
    boolDecoding: .numericOrString,
    lenientNumberParsing: true,
    maxDepth: 64,
    maxArrayCount: 10_000,
    envelope: nil,
    outputFormatting: []
  )

  /// Lenient API preset used by ``FKModelMapper/shared``.
  public static let lenientAPI = FKModelMappingConfiguration(
    keyStrategy: .convertFromSnakeCase,
    unknownKeyStrategy: .ignore,
    nilValueStrategy: [.treatNullAsNil, .treatEmptyStringAsNil],
    mappingMode: .lenient,
    encodeNullStrategy: .encodeNull,
    dateDecoding: .iso8601,
    dateEncoding: .iso8601,
    dataDecoding: .base64,
    boolDecoding: .numericOrString,
    lenientNumberParsing: true,
    maxDepth: 64,
    maxArrayCount: 10_000,
    envelope: nil,
    outputFormatting: []
  )

  /// Fully strict preset without loose typing helpers.
  public static let strict = FKModelMappingConfiguration(
    keyStrategy: .useDefaultKeys,
    unknownKeyStrategy: .fail,
    nilValueStrategy: .standard,
    mappingMode: .strict,
    encodeNullStrategy: .encodeNull,
    dateDecoding: .iso8601,
    dateEncoding: .iso8601,
    dataDecoding: .base64,
    boolDecoding: .jsonBool,
    lenientNumberParsing: false,
    maxDepth: 32,
    maxArrayCount: 5_000,
    envelope: nil,
    outputFormatting: []
  )

  /// Creates a mapping configuration.
  public init(
    keyStrategy: FKMappingKeyStrategy = .useDefaultKeys,
    unknownKeyStrategy: FKUnknownKeyStrategy = .ignore,
    nilValueStrategy: FKNilValueStrategy = .standard,
    mappingMode: FKMappingMode = .strict,
    encodeNullStrategy: FKEncodeNullStrategy = .encodeNull,
    dateDecoding: FKDateDecodingStrategy = .iso8601,
    dateEncoding: FKDateEncodingStrategy = .iso8601,
    dataDecoding: FKDataDecodingStrategy = .base64,
    boolDecoding: FKBoolDecodingStrategy = .jsonBool,
    lenientNumberParsing: Bool = false,
    maxDepth: Int = 64,
    maxArrayCount: Int = 10_000,
    envelope: FKResponseEnvelopeConfiguration? = nil,
    outputFormatting: JSONEncoder.OutputFormatting = []
  ) {
    self.keyStrategy = keyStrategy
    self.unknownKeyStrategy = unknownKeyStrategy
    self.nilValueStrategy = nilValueStrategy
    self.mappingMode = mappingMode
    self.encodeNullStrategy = encodeNullStrategy
    self.dateDecoding = dateDecoding
    self.dateEncoding = dateEncoding
    self.dataDecoding = dataDecoding
    self.boolDecoding = boolDecoding
    self.lenientNumberParsing = lenientNumberParsing
    self.maxDepth = maxDepth
    self.maxArrayCount = maxArrayCount
    self.envelope = envelope
    self.outputFormatting = outputFormatting
  }
}
