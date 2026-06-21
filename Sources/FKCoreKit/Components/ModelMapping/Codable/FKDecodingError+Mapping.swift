import Foundation

enum FKDecodingErrorMapper {
  static func map(_ error: Error, fallbackPath: [String] = []) -> FKMappingError {
    if let mappingError = error as? FKMappingError {
      return mappingError
    }

    guard let decodingError = error as? DecodingError else {
      return .decodingFailed(underlying: error, codingPath: fallbackPath)
    }

    switch decodingError {
    case let .keyNotFound(key, context):
      return .keyNotFound(path: codingPath(from: context, key: key.stringValue))
    case let .typeMismatch(type, context):
      return .typeMismatch(
        path: codingPath(from: context, key: nil),
        expected: String(describing: type),
        actual: FKI18n.string("fkcore.mapping.error.unknown_actual_type")
      )
    case let .valueNotFound(type, context):
      return .valueNotFound(path: codingPath(from: context, key: String(describing: type)))
    case let .dataCorrupted(context):
      return .invalidJSON(underlying: context.underlyingError ?? decodingError)
    @unknown default:
      return .decodingFailed(underlying: decodingError, codingPath: fallbackPath)
    }
  }

  private static func codingPath(from context: DecodingError.Context, key: String?) -> String {
    var components = context.codingPath.map(\.stringValue)
    if let key, !components.contains(key) {
      components.append(key)
    }
    return components.joined(separator: ".")
  }
}
