import Foundation

/// Unified mapping facade for JSON data, strings, and dynamic dictionaries.
public struct FKModelMapper: Sendable {
  /// Shared mapper using ``FKModelMappingConfiguration/lenientAPI``.
  public static let shared = FKModelMapper(configuration: .lenientAPI)

  private let configuration: FKModelMappingConfiguration
  private let transformRegistry: FKTransformRegistry
  private let codec: FKJSONCodec
  private let dictionaryMapper: FKDictionaryMapper
  private let envelopeProcessor: FKResponseEnvelopeProcessor?
  private let logger: FKMappingLogging

  /// Creates a model mapper.
  public init(
    configuration: FKModelMappingConfiguration = .standard,
    transformRegistry: FKTransformRegistry = .default,
    logger: FKMappingLogging = FKNoOpMappingLogger()
  ) {
    self.configuration = configuration
    self.transformRegistry = transformRegistry
    codec = FKJSONCodec(configuration: configuration)
    dictionaryMapper = FKDictionaryMapper(configuration: configuration, transformRegistry: transformRegistry)
    if let envelope = configuration.envelope {
      envelopeProcessor = FKResponseEnvelopeProcessor(
        configuration: envelope,
        mappingConfiguration: configuration
      )
    } else {
      envelopeProcessor = nil
    }
    self.logger = logger
  }

  /// Current mapping configuration snapshot.
  public var mappingConfiguration: FKModelMappingConfiguration {
    configuration
  }

  /// Underlying JSON codec.
  public var jsonCodec: FKJSONCodec {
    codec
  }

  /// Builds a configured ``JSONDecoder`` for ``FKNetworkClient`` injection.
  public func makeDecoder() -> JSONDecoder {
    codec.makeDecoder()
  }

  /// Builds a configured ``JSONEncoder``.
  public func makeEncoder() -> JSONEncoder {
    codec.makeEncoder()
  }

  /// Decodes a model from JSON data.
  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let start = Date()
    do {
      let value = try codec.decode(type, from: data)
      logger.didDecode(type: type, path: nil, duration: Date().timeIntervalSince(start))
      return value
    } catch {
      let mappingError = normalize(error)
      logger.didFail(error: mappingError, preview: data.prefix(256))
      throw mappingError
    }
  }

  /// Decodes a model from a UTF-8 JSON string.
  public func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
    guard let data = string.data(using: .utf8) else {
      throw FKMappingError.invalidJSON(underlying: FKJSONExtensionError.invalidUTF8)
    }
    return try decode(type, from: data)
  }

  /// Decodes a ``FKMappable`` model from a dynamic dictionary.
  public func decode<T: FKMappable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
    try dictionaryMapper.decode(type, from: dictionary)
  }

  /// Decodes a ``Decodable`` model from a dynamic dictionary via JSON serialization.
  public func decodeDecodable<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
    guard JSONSerialization.isValidJSONObject(dictionary),
          let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
      throw FKMappingError.invalidJSON(underlying: nil)
    }
    return try decode(type, from: data)
  }

  /// Decodes a model from an envelope wrapped JSON payload.
  public func decodeEnvelope<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let payload = try unwrapEnvelope(data: data)
    return try decode(type, from: payload)
  }

  /// Decodes a ``Decodable`` model using lenient mapping configuration.
  ///
  /// For ``FKMappable`` models, prefer the dictionary overload to collect warnings.
  public func decodeLenient<T: Decodable>(_ type: T.Type, from data: Data) throws -> FKMappingResult<T> {
    var lenientConfiguration = configuration
    lenientConfiguration.mappingMode = .lenient
    let mapper = FKModelMapper(
      configuration: lenientConfiguration,
      transformRegistry: transformRegistry,
      logger: logger
    )
    let value = try mapper.decode(type, from: data)
    return FKMappingResult(value: value)
  }

  /// Decodes a ``FKMappable`` model leniently and returns collected warnings.
  public func decodeLenient<T: FKMappable>(
    _ type: T.Type,
    from dictionary: [String: Any]
  ) throws -> FKMappingResult<T> {
    try dictionaryMapper.decodeLenient(type, from: dictionary)
  }

  /// Encodes a model to JSON data.
  public func encode<T: Encodable>(_ value: T) throws -> Data {
    do {
      return try codec.encode(value)
    } catch {
      let mappingError = normalize(error)
      logger.didFail(error: mappingError, preview: nil)
      throw mappingError
    }
  }

  /// Encodes a model to a UTF-8 JSON string.
  public func encodeString<T: Encodable>(_ value: T) throws -> String {
    try codec.encodeString(value)
  }

  /// Encodes a model to a JSON object dictionary.
  public func dictionary<T: Encodable>(from value: T) throws -> [String: Any] {
    let data = try encode(value)
    let object = try FKJSONParser.parseJSONObject(
      from: data,
      maxDepth: configuration.maxDepth,
      maxArrayCount: configuration.maxArrayCount
    )
    guard let dictionary = object as? [String: Any] else {
      throw FKMappingError.encodingFailed(underlying: FKMappingError.invalidJSON(underlying: nil))
    }
    return dictionary
  }

  private func unwrapEnvelope(data: Data) throws -> Data {
    guard let envelopeProcessor else { return data }
    return try envelopeProcessor.process(data: data).payload
  }

  private func normalize(_ error: Error) -> FKMappingError {
    if let mappingError = error as? FKMappingError {
      return mappingError
    }
    return FKDecodingErrorMapper.map(error)
  }
}
