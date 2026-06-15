#if os(iOS)
import Foundation
@preconcurrency import UserNotifications

enum FKLocalNotificationErrorMapper {
  static func map(_ error: Error) -> FKLocalNotificationError {
    let nsError = error as NSError
    if nsError.domain == UNErrorDomain {
      return .systemError("UNError(\(nsError.code)): \(nsError.localizedDescription)")
    }
    return .systemError(error.localizedDescription)
  }
}

#endif
