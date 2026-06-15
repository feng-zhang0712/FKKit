import FKCoreKit
import UIKit

/// B7 — deeplink routing from notification userInfo on tap.
final class FKLocalNotificationExampleDeeplinkTapViewController: FKLocalNotificationExampleBaseViewController {
  private let kit = FKBusinessKit.shared

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Deeplink Tap"

    FKLocalNotificationExampleSupport.installDelegate { [weak self] in self?.appendLog($0) }
    registerDemoRoutes()

    addInfoLabel(
      "Tap the notification (or wait for foreground banner) to route fk.deeplink.url via BusinessKit or a custom router."
    )

    addSectionHeading("BusinessKit bridge")
    addActionButton("useBusinessKitDeeplink()") { [weak self] in
      FKLocalNotificationExampleSupport.manager.useBusinessKitDeeplink()
      FKLocalNotificationExampleSupport.wireResponseHandler { self?.appendLog($0) }
      self?.appendLog("useBusinessKitDeeplink() — routes with FKDeeplinkSource.unknown")
    }

    addActionButton("Schedule notification with inbox deeplink (5s)") { [weak self] in
      self?.scheduleDeeplinkNotification(
        url: "https://fkkit.example/inbox/42?source=local",
        id: "deeplink-businesskit"
      )
    }

    addSectionHeading("Custom router")
    addActionButton("setDeeplinkRouter (custom closure)") { [weak self] in
      FKLocalNotificationExampleSupport.manager.setDeeplinkRouter { url in
        Task { @MainActor in
          self?.appendLog("custom router → \(url.absoluteString)")
        }
        return true
      }
      FKLocalNotificationExampleSupport.wireResponseHandler { self?.appendLog($0) }
    }

    addActionButton("Schedule notification with promo deeplink (5s)") { [weak self] in
      self?.scheduleDeeplinkNotification(
        url: "https://fkkit.example/promo/spring",
        id: "deeplink-custom"
      )
    }

    addSectionHeading("Configuration: route before handler")
    addActionButton("Demo routeDeeplinkBeforeResponseHandler = true") { [weak self] in
      self?.appendLog(
        "Create a dedicated FKLocalNotificationManager(configuration:) with routeDeeplinkBeforeResponseHandler: true for apps that need routing before UI handlers."
      )
      let configured = FKLocalNotificationManager(
        configuration: FKLocalNotificationManagerConfiguration(
          automaticallyInstallDelegate: true,
          routeDeeplinkBeforeResponseHandler: true
        )
      )
      configured.useBusinessKitDeeplink()
      configured.setResponseHandler { response in
        Task { @MainActor in
          self?.appendLog("handler after route — action=\(response.actionIdentifier)")
        }
      }
      self?.runTask("configured.schedule") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await configured.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("route-first"),
            content: FKLocalNotificationContent(
              title: "Route first",
              body: "Deeplink runs before responseHandler.",
              userInfo: [FKLocalNotificationUserInfoKey.deeplinkURL: "https://fkkit.example/inbox/99"]
            ),
            trigger: .timeInterval(5, repeats: false)
          )
        )
        self?.appendLog("Scheduled via custom manager instance (separate from .shared)")
      }
    }

    addClearLogButton()
  }

  private func registerDemoRoutes() {
    kit.deeplink.register(
      FKDeeplinkRoute(id: "inbox", host: "fkkit.example", pathPattern: "/inbox/*") { [weak self] context in
        Task { @MainActor in
          self?.appendLog("BusinessKit matched inbox — params=\(context.parameters)")
        }
        return true
      }
    )
    kit.deeplink.register(
      FKDeeplinkRoute(id: "promo", host: "fkkit.example", pathPattern: "/promo/*") { [weak self] context in
        Task { @MainActor in
          self?.appendLog("BusinessKit matched promo — params=\(context.parameters)")
        }
        return true
      }
    )
  }

  private func scheduleDeeplinkNotification(url: String, id: String) {
    runTask("schedule.\(id)") {
      guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self.appendLog($0) }) else {
        throw FKLocalNotificationError.notAuthorized
      }
      try await FKLocalNotificationExampleSupport.manager.schedule(
        FKLocalNotificationRequest(
          identifier: FKLocalNotificationExampleSupport.identifier(id),
          content: FKLocalNotificationContent(
            title: "Deeplink notification",
            body: "Tap to open \(url)",
            userInfo: [FKLocalNotificationUserInfoKey.deeplinkURL: url]
          ),
          trigger: .timeInterval(5, repeats: false)
        )
      )
    }
  }
}
