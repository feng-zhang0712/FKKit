import Foundation

public extension FKMappingError {
  /// Maps a mapping failure to ``NetworkError`` for FKNetwork integration.
  func asNetworkError() -> NetworkError {
    switch self {
    case let .businessFailure(code, message, _):
      return .businessError(code: code, message: message ?? FKI18n.string("fkcore.mapping.error.unknown_business_message"))
    case let .decodingFailed(underlying, _):
      return .decodingFailed(underlying: underlying)
    case let .invalidJSON(underlying):
      return .decodingFailed(underlying: underlying ?? self)
    case let .nested(error):
      return error.asNetworkError()
    case let .encodingFailed(underlying):
      return .decodingFailed(underlying: underlying)
    default:
      return .decodingFailed(underlying: self)
    }
  }
}
