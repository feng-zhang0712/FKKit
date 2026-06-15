import FKCoreKit
import UIKit

/// B2 — time interval, immediate delivery, rich content, repeating interval, delegate wiring.
final class FKLocalNotificationExampleScheduleIntervalViewController: FKLocalNotificationExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B2 Interval & Content"

    addInfoLabel(
      "Install the delegate so notifications appear as banners while the app stays in the foreground. Background the app to see lock-screen delivery."
    )

    addActionButton("installDelegate + setResponseHandler") { [weak self] in
      FKLocalNotificationExampleSupport.installDelegate { self?.appendLog($0) }
      FKLocalNotificationExampleSupport.wireResponseHandler { self?.appendLog($0) }
    }

    addSectionHeading("Triggers")
    addActionButton("Schedule in 10 seconds") { [weak self] in
      self?.scheduleDemo(
        id: "interval-10s",
        title: "Interval trigger",
        body: "Fired 10 seconds after scheduling.",
        trigger: .timeInterval(10, repeats: false)
      )
    }

    addActionButton("Deliver immediately (trigger: nil)") { [weak self] in
      self?.scheduleDemo(
        id: "immediate",
        title: "Immediate",
        body: "Delivered as soon as authorized.",
        trigger: .immediate
      )
    }

    addActionButton("Repeating every 60 seconds (system minimum)") { [weak self] in
      self?.scheduleDemo(
        id: "repeat-60s",
        title: "Repeating interval",
        body: "Repeats every 60 seconds until cancelled.",
        trigger: .timeInterval(60, repeats: true)
      )
    }

    addSectionHeading("Rich FKLocalNotificationContent")
    addActionButton("Schedule with subtitle, silent sound, userInfo keys, thread") { [weak self] in
      self?.runTask("rich-content") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        let request = FKLocalNotificationRequest(
          identifier: FKLocalNotificationExampleSupport.identifier("rich-content"),
          content: FKLocalNotificationContent(
            title: "Order update",
            body: "Package scanned at the hub.",
            subtitle: "Tracking #12847",
            sound: .none,
            badge: 1,
            userInfo: [
              FKLocalNotificationUserInfoKey.routeID: "orders/12847",
              FKLocalNotificationUserInfoKey.analyticsEvent: "notification_opened",
            ],
            threadIdentifier: "orders",
            targetContentIdentifier: "order-detail",
            relevanceScore: 0.8
          ),
          trigger: .timeInterval(8, repeats: false)
        )
        try await FKLocalNotificationExampleSupport.manager.schedule(request)
        self?.appendLog("Rich content scheduled with standard userInfo keys")
      }
    }

    addActionButton("Cancel repeating demo") { [weak self] in
      self?.runTask("cancel.repeat") {
        await FKLocalNotificationExampleSupport.manager.cancelPending(
          withIdentifier: FKLocalNotificationExampleSupport.identifier("repeat-60s")
        )
      }
    }

    addClearLogButton()
  }

  private func scheduleDemo(
    id: String,
    title: String,
    body: String,
    trigger: FKLocalNotificationTrigger
  ) {
    runTask("schedule.\(id)") {
      guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self.appendLog($0) }) else {
        throw FKLocalNotificationError.notAuthorized
      }
      try await FKLocalNotificationExampleSupport.manager.schedule(
        FKLocalNotificationRequest(
          identifier: FKLocalNotificationExampleSupport.identifier(id),
          content: FKLocalNotificationContent(title: title, body: body),
          trigger: trigger
        )
      )
    }
  }
}
