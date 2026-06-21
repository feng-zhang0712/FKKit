import Foundation

/// Response envelope field mapping and success code rules.
public struct FKResponseEnvelopeConfiguration: Sendable, Equatable {
  /// Payload key containing business data.
  public var payloadKey: String
  /// Business code key.
  public var codeKey: String
  /// Business message key.
  public var messageKey: String
  /// Business codes treated as success.
  public var successCodes: Set<Int>
  /// Optional boolean success flag key.
  public var successBoolKey: String?
  /// Optional nested payload path such as `result.items`.
  public var nestedPayloadPath: String?

  /// Standard `{ code, message, data }` envelope.
  public static let standard = FKResponseEnvelopeConfiguration(
    payloadKey: "data",
    codeKey: "code",
    messageKey: "message",
    successCodes: [0],
    successBoolKey: nil,
    nestedPayloadPath: nil
  )

  /// `{ success, result }` style envelope.
  public static let successFlag = FKResponseEnvelopeConfiguration(
    payloadKey: "result",
    codeKey: "code",
    messageKey: "message",
    successCodes: [0],
    successBoolKey: "success",
    nestedPayloadPath: nil
  )

  /// Creates an envelope configuration.
  public init(
    payloadKey: String = "data",
    codeKey: String = "code",
    messageKey: String = "message",
    successCodes: Set<Int> = [0],
    successBoolKey: String? = nil,
    nestedPayloadPath: String? = nil
  ) {
    self.payloadKey = payloadKey
    self.codeKey = codeKey
    self.messageKey = messageKey
    self.successCodes = successCodes
    self.successBoolKey = successBoolKey
    self.nestedPayloadPath = nestedPayloadPath
  }
}

/// Result of envelope processing before model decoding.
public struct FKEnvelopeResult: Sendable {
  /// Extracted payload encoded as JSON `Data`.
  public var payload: Data
  /// Business code when present.
  public var businessCode: Int?
  /// Business message when present.
  public var businessMessage: String?

  /// Creates an envelope result.
  public init(payload: Data, businessCode: Int? = nil, businessMessage: String? = nil) {
    self.payload = payload
    self.businessCode = businessCode
    self.businessMessage = businessMessage
  }
}

/// Unwraps common API envelopes and validates business success codes.
public struct FKResponseEnvelopeProcessor: Sendable {
  private let configuration: FKResponseEnvelopeConfiguration
  private let mappingConfiguration: FKModelMappingConfiguration

  /// Creates an envelope processor.
  ///
  /// - Parameters:
  ///   - configuration: Envelope field mapping.
  ///   - mappingConfiguration: Limits and nil normalization for parsing.
  public init(
    configuration: FKResponseEnvelopeConfiguration,
    mappingConfiguration: FKModelMappingConfiguration = .standard
  ) {
    self.configuration = configuration
    self.mappingConfiguration = mappingConfiguration
  }

  /// Processes raw JSON data and returns the inner payload.
  public func process(data: Data) throws -> FKEnvelopeResult {
    let object = try FKJSONParser.parseJSONObject(
      from: data,
      maxDepth: mappingConfiguration.maxDepth,
      maxArrayCount: mappingConfiguration.maxArrayCount
    )
    guard let dictionary = object as? [String: Any] else {
      throw FKMappingError.invalidJSON(underlying: nil)
    }

    let businessCode = FKEnvelopeValueParser.int(from: dictionary[configuration.codeKey])
    let businessMessage = FKValueParsing.string(from: dictionary[configuration.messageKey])

    if let successBoolKey = configuration.successBoolKey,
       let successValue = dictionary[successBoolKey] {
      let isSuccess = FKEnvelopeValueParser.bool(from: successValue) ?? false
      if !isSuccess {
        throw FKMappingError.businessFailure(
          code: businessCode ?? -1,
          message: businessMessage,
          payload: data
        )
      }
    } else if let businessCode, !configuration.successCodes.contains(businessCode) {
      throw FKMappingError.businessFailure(
        code: businessCode,
        message: businessMessage,
        payload: data
      )
    }

    let payloadPath = configuration.nestedPayloadPath ?? configuration.payloadKey
    guard let payloadValue = FKJSONPathResolver.resolve(path: payloadPath, in: dictionary) else {
      if dictionary[configuration.payloadKey] is NSNull {
        return FKEnvelopeResult(payload: Data("null".utf8), businessCode: businessCode, businessMessage: businessMessage)
      }
      throw FKMappingError.keyNotFound(path: payloadPath)
    }

    if payloadValue is NSNull {
      return FKEnvelopeResult(payload: Data("null".utf8), businessCode: businessCode, businessMessage: businessMessage)
    }

    guard JSONSerialization.isValidJSONObject(payloadValue) else {
      throw FKMappingError.invalidJSON(underlying: nil)
    }

    let payloadData = try JSONSerialization.data(withJSONObject: payloadValue, options: [])
    return FKEnvelopeResult(payload: payloadData, businessCode: businessCode, businessMessage: businessMessage)
  }
}

/// Network response interceptor that unwraps configured API envelopes for HTTP 2xx responses.
public struct FKResponseEnvelopeInterceptor: ResponseInterceptor, Sendable {
  private let processor: FKResponseEnvelopeProcessor

  /// Creates an envelope interceptor.
  public init(
    configuration: FKResponseEnvelopeConfiguration,
    mappingConfiguration: FKModelMappingConfiguration = .standard
  ) {
    processor = FKResponseEnvelopeProcessor(
      configuration: configuration,
      mappingConfiguration: mappingConfiguration
    )
  }

  /// Unwraps the envelope when the HTTP status code is successful.
  public func intercept(data: Data, response: HTTPURLResponse) throws -> Data {
    guard (200 ... 299).contains(response.statusCode) else {
      return data
    }
    return try processor.process(data: data).payload
  }
}

enum FKEnvelopeValueParser {
  static func int(from value: Any?) -> Int? {
    FKValueParsing.int(from: value)
  }

  static func bool(from value: Any?) -> Bool? {
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
}
