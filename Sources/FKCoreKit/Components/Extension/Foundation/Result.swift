import Foundation

public extension Result {
  /// Wrapped success value or `nil` when `.failure`.
  var fk_successValue: Success? {
    switch self {
    case let .success(value):
      return value
    case .failure:
      return nil
    }
  }

  /// Wrapped failure value or `nil` when `.success`.
  var fk_failureValue: Failure? {
    switch self {
    case .success:
      return nil
    case let .failure(error):
      return error
    }
  }
}
