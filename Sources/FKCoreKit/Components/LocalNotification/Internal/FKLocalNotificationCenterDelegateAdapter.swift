#if os(iOS)
import Foundation
@preconcurrency import UserNotifications

/// Forwards `UNUserNotificationCenterDelegate` callbacks to ``FKLocalNotificationManager``.
final class FKLocalNotificationCenterDelegateAdapter: NSObject, UNUserNotificationCenterDelegate {
  var presentationOptions: FKLocalNotificationPresentationOptions = .standard
  var routeDeeplinkBeforeResponseHandler = false

  private let stateQueue = DispatchQueue(label: "com.fkkit.local-notification.delegate")
  private var responseHandler: FKLocalNotificationResponseHandler?
  private var deeplinkRouter: (@Sendable (URL) -> Bool)?

  func setResponseHandler(_ handler: FKLocalNotificationResponseHandler?) {
    stateQueue.sync { responseHandler = handler }
  }

  func setDeeplinkRouter(_ router: (@Sendable (URL) -> Bool)?) {
    stateQueue.sync { deeplinkRouter = router }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler(mapPresentationOptions(presentationOptions))
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let fkResponse = Self.makeResponse(from: response)
    let snapshot = stateQueue.sync { () -> (FKLocalNotificationResponseHandler?, (@Sendable (URL) -> Bool)?, Bool) in
      (responseHandler, deeplinkRouter, routeDeeplinkBeforeResponseHandler)
    }
    let handler = snapshot.0
    let router = snapshot.1
    let routeFirst = snapshot.2

    let deliverResponse = {
      if routeFirst {
        self.routeDeeplinkIfNeeded(userInfo: fkResponse.userInfo, router: router)
        handler?(fkResponse)
      } else {
        handler?(fkResponse)
        self.routeDeeplinkIfNeeded(userInfo: fkResponse.userInfo, router: router)
      }
      completionHandler()
    }

    if Thread.isMainThread {
      deliverResponse()
    } else {
      DispatchQueue.main.async(execute: deliverResponse)
    }
  }

  private func routeDeeplinkIfNeeded(
    userInfo: [String: String],
    router: (@Sendable (URL) -> Bool)?
  ) {
    guard let router,
          let urlString = userInfo[FKLocalNotificationUserInfoKey.deeplinkURL],
          let url = URL(string: urlString) else {
      return
    }
    _ = router(url)
  }

  private func mapPresentationOptions(
    _ options: FKLocalNotificationPresentationOptions
  ) -> UNNotificationPresentationOptions {
    var unOptions: UNNotificationPresentationOptions = []
    if options.contains(.banner) { unOptions.insert(.banner) }
    if options.contains(.list) { unOptions.insert(.list) }
    if options.contains(.sound) { unOptions.insert(.sound) }
    if options.contains(.badge) { unOptions.insert(.badge) }
    return unOptions
  }

  private static func makeResponse(from response: UNNotificationResponse) -> FKLocalNotificationResponse {
    let userInfo = FKLocalNotificationRequestMapper.makeFKContent(from: response.notification.request.content).userInfo
    let actionIdentifier = response.actionIdentifier
    let isDefault = actionIdentifier == UNNotificationDefaultActionIdentifier
    return FKLocalNotificationResponse(
      requestIdentifier: response.notification.request.identifier,
      actionIdentifier: actionIdentifier,
      userInfo: userInfo,
      isDefaultAction: isDefault
    )
  }
}

#endif
