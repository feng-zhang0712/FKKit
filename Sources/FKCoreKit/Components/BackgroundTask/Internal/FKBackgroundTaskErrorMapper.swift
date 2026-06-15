#if os(iOS)
import Foundation
@preconcurrency import BackgroundTasks

enum FKBackgroundTaskErrorMapper {
  static func mapSubmitError(_ error: Error, identifier: String) -> FKBackgroundTaskError {
    if let schedulerError = error as? BGTaskScheduler.Error {
      switch schedulerError.code {
      case .notPermitted:
        return .identifierNotPermitted(identifier)
      case .tooManyPendingTaskRequests, .unavailable:
        return .schedulingFailed(code: schedulerError.code.rawValue)
      @unknown default:
        return .schedulingFailed(code: schedulerError.code.rawValue)
      }
    }

    let nsError = error as NSError
    if nsError.domain == BGTaskScheduler.errorDomain {
      if nsError.code == BGTaskScheduler.Error.Code.notPermitted.rawValue {
        return .identifierNotPermitted(identifier)
      }
      return .schedulingFailed(code: nsError.code)
    }

    return .schedulingFailed(code: nsError.code)
  }
}

#endif
